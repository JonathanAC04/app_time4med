import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

admin.initializeApp();
const db = admin.firestore();

type Role = "admin" | "paciente" | "doctor";

function normEmail(email: string) {
  return (email || "").trim().toLowerCase();
}

async function assertAdmin(callerUid: string) {
  const snap = await db.collection("users").doc(callerUid).get();
  const rol = snap.exists ? (snap.get("rol") as string) : null;
  if (rol !== "admin") {
    throw new HttpsError("permission-denied", "Solo admin puede ejecutar esta acción.");
  }
}

export const adminCreateInvite = onCall(async (req) => {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Debes iniciar sesión.");

  await assertAdmin(auth.uid);

  const data = req.data || {};
  const email = normEmail(String(data.email || ""));
  const rol = String(data.rol || "") as Role;
  const nombre = String(data.nombre || "").trim();

  if (!email) throw new HttpsError("invalid-argument", "email es requerido.");
  if (rol !== "doctor" && rol !== "paciente") {
    throw new HttpsError("invalid-argument", "rol debe ser 'doctor' o 'paciente'.");
  }
  if (!nombre) throw new HttpsError("invalid-argument", "nombre es requerido.");

  const inviteId = email; // key por emailLower
  const inviteRef = db.collection("invites").doc(inviteId);

  const invite: Record<string, unknown> = {
    email,
    rol,
    nombre,
    createdBy: auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (rol === "doctor") {
    invite.especialidad = String(data.especialidad || "").trim();
    invite.cedula = String(data.cedula || "").trim();
    invite.telefono = String(data.telefono || "").trim();
    invite.fotoUrl = String(data.fotoUrl || "").trim(); // opcional
  }

  if (rol === "paciente") {
    const doctorId = String(data.doctorId || "").trim();
    if (doctorId) invite.doctorId = doctorId; // asignación opcional en la invitación
  }

  await inviteRef.set(invite, { merge: true });

  return { ok: true, inviteId };
});

export const adminListDoctors = onCall(async (req) => {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Debes iniciar sesión.");

  await assertAdmin(auth.uid);

  const qs = await db.collection("users").where("rol", "==", "doctor").get();

  const doctors = qs.docs.map((d) => ({
    uid: d.id,
    nombre: (d.get("nombre") as string) || "",
    email: (d.get("email") as string) || "",
    especialidad: (d.get("especialidad") as string) || "",
  }));

  return { ok: true, doctors };
});

export const acceptInvite = onCall(async (req) => {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Debes iniciar sesión.");

  const callerUid = auth.uid;
  const callerEmail = normEmail(String(auth.token.email || ""));
  if (!callerEmail) {
    throw new HttpsError("failed-precondition", "Tu usuario no tiene email en Auth.");
  }

  const inviteRef = db.collection("invites").doc(callerEmail);
  const inviteSnap = await inviteRef.get();

  if (!inviteSnap.exists) {
    return { ok: true, applied: false, reason: "no-invite" };
  }

  const invite = inviteSnap.data() || {};
  const rol = String(invite.rol || "") as Role;
  const nombre = String(invite.nombre || "").trim();
  const doctorId = String(invite.doctorId || "").trim();

  if (rol !== "doctor" && rol !== "paciente") {
    throw new HttpsError("failed-precondition", "Invitación inválida (rol).");
  }

  const userRef = db.collection("users").doc(callerUid);
  const userSnap = await userRef.get();

  const baseUpdate: Record<string, unknown> = {
    rol,
    email: callerEmail,
    nombre,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (!userSnap.exists) {
    baseUpdate.createdAt = admin.firestore.FieldValue.serverTimestamp();
  }

  if (rol === "doctor") {
    baseUpdate.especialidad = String(invite.especialidad || "").trim();
    baseUpdate.cedula = String(invite.cedula || "").trim();
    baseUpdate.telefono = String(invite.telefono || "").trim();
    baseUpdate.fotoUrl = String(invite.fotoUrl || "").trim();
  }

  if (rol === "paciente") {
    // asignación 1 paciente -> 1 doctor
    if (doctorId) baseUpdate.doctorId = doctorId;
  }

  await db.runTransaction(async (tx) => {
    tx.set(userRef, baseUpdate, { merge: true });
    tx.delete(inviteRef); // borrar invitación al aplicar
  });

  logger.info("Invite applied", { callerUid, callerEmail, rol });

  return { ok: true, applied: true, rol };
});

export const adminAssignPatientToDoctor = onCall(async (req) => {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Debes iniciar sesión.");

  await assertAdmin(auth.uid);

  const data = req.data || {};
  const patientUid = String(data.patientUid || "").trim();
  const doctorUid = String(data.doctorUid || "").trim(); // puede ser "" para desasignar

  if (!patientUid) throw new HttpsError("invalid-argument", "patientUid es requerido.");

  const patientRef = db.collection("users").doc(patientUid);
  const patientSnap = await patientRef.get();
  if (!patientSnap.exists) throw new HttpsError("not-found", "Paciente no encontrado.");

  // opcional: validar que doctorUid exista y sea doctor
  if (doctorUid) {
    const doctorSnap = await db.collection("users").doc(doctorUid).get();
    if (!doctorSnap.exists) throw new HttpsError("not-found", "Doctor no encontrado.");
    if (doctorSnap.get("rol") !== "doctor") {
      throw new HttpsError("failed-precondition", "El UID proporcionado no es doctor.");
    }
  }

  await patientRef.set(
    {
      doctorId: doctorUid || admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true };
});