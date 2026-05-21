import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../utils/date_helpers.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Función para obtener el rol del usuario
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final rol = ((data['rol'] ?? data['role']) as String? ?? '')
            .trim()
            .toLowerCase();
        if (rol == 'patient') return 'paciente';
        if (rol == 'doctor' || rol == 'admin' || rol == 'paciente') return rol;
      }
      return null;
    } catch (e) {
      print("Error en Firestore: $e");
      return null;
    }
  }

  // Obtiene todos los datos del documento del usuario
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error al obtener datos del usuario: $e");
      return null;
    }
  }

  // Agrega un medicamento a la subcolección del paciente
  Future<String> addMedicamento(
      String uid, String nombre, String dosis, DateTime fechaHora) async {
    final fecha = formatDateToString(fechaHora);
    final hora = formatTimeToString(fechaHora);
    final docRef =
        await _db.collection('users').doc(uid).collection('medicamentos').add({
      'nombre': nombre,
      'dosis': dosis,
      'hora': hora,
      'fecha': fecha,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'status': 'PENDIENTE',
      'creado': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Stream en tiempo real de los medicamentos del paciente
  Stream<QuerySnapshot<Map<String, dynamic>>> getMedicamentosStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('medicamentos')
        .orderBy('creado', descending: false)
        .snapshots();
  }

  // Actualiza el estado (status) de un medicamento
  Future<void> updateMedicamentoStatus(
      String uid, String docId, String status) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicamentos')
        .doc(docId)
        .update({'status': status});
  }

  // Actualiza los campos de un medicamento
  Future<void> updateMedicamento(
      String uid, String docId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicamentos')
        .doc(docId)
        .update(data);
  }

  // Elimina un medicamento
  Future<void> deleteMedicamento(String uid, String docId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('medicamentos')
        .doc(docId)
        .delete();
  }

  // Agrega una cita médica a la subcolección del paciente
  Future<String> addCita(
      String uid, DateTime fecha, TimeOfDay hora, String motivo) async {
    final docRef = await _db.collection('users').doc(uid).collection('citas').add({
      'fecha': formatDateToString(fecha),
      'hora':
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      'fechaHora': Timestamp.fromDate(DateTime(
          fecha.year, fecha.month, fecha.day, hora.hour, hora.minute)),
      'motivo': motivo,
      'creado': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Stream en tiempo real de las citas del paciente (ordenadas por fechaHora)
  Stream<QuerySnapshot<Map<String, dynamic>>> getCitasStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('citas')
        .orderBy('fechaHora', descending: false)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getMedicamentosOnce(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('medicamentos')
        .orderBy('creado', descending: false)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCitasOnce(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('citas')
        .orderBy('fechaHora', descending: false)
        .get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    final currentDoc = await _db.collection('users').doc(uid).get();
    final currentData = currentDoc.data() ?? <String, dynamic>{};
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

    final role = (currentData['rol'] as String?) ?? '';
    final doctorId = (currentData['doctorId'] as String?)?.trim();
    if (role != 'paciente' || doctorId == null || doctorId.isEmpty) return;

    const camposRelevantes = <String>{
      'nombre',
      'apellidos',
      'sexo',
      'tipoSangre',
      'peso',
      'estatura',
      'fechaNacimiento',
      'contactoEmergenciaNombre',
      'contactoEmergenciaTelefono',
      'imc',
    };

    bool cambioRelevante = false;
    for (final entry in data.entries) {
      if (!camposRelevantes.contains(entry.key)) continue;
      final previous = currentData[entry.key]?.toString() ?? '';
      final next = entry.value?.toString() ?? '';
      if (previous != next) {
        cambioRelevante = true;
        break;
      }
    }

    if (!cambioRelevante) return;
    final patientName = (currentData['nombre'] as String?)?.trim();
    await addDoctorNotification(
      doctorId: doctorId,
      patientId: uid,
      patientName:
          patientName == null || patientName.isEmpty ? 'Paciente' : patientName,
      title: 'Actualización de datos del paciente',
      body: 'Actualizó su información personal y de salud.',
      type: 'PATIENT_PROFILE_UPDATED',
    );
  }

  // Obtiene el conteo de usuarios por rol
  Future<int> countUsersByRole(String rol) async {
    try {
      QuerySnapshot snapshot =
          await _db.collection('users').where('rol', isEqualTo: rol).get();
      return snapshot.size;
    } catch (e) {
      print("Error contando usuarios: $e");
      return 0;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDoctorPatients(
      String doctorId) {
    return _db
        .collection('users')
        .where('rol', isEqualTo: 'paciente')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsersByRole(String role) {
    return _db.collection('users').where('rol', isEqualTo: role).snapshots();
  }

  Future<void> setUserProfile(
    String uid,
    Map<String, dynamic> data, {
    bool merge = true,
  }) {
    return _db.collection('users').doc(uid).set(data, SetOptions(merge: merge));
  }

  Future<void> assignPatientToDoctor({
    required String patientId,
    String? doctorId,
    String? doctorName,
  }) async {
    final payload = <String, dynamic>{
      'doctorId': doctorId == null || doctorId.isEmpty
          ? FieldValue.delete()
          : doctorId,
      'medico': doctorName == null || doctorName.isEmpty
          ? FieldValue.delete()
          : doctorName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db
        .collection('users')
        .doc(patientId)
        .set(payload, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream(
      String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notificaciones')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addNotificationToUser({
    required String uid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    await _db.collection('users').doc(uid).collection('notificaciones').add({
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extraData,
    });
  }

  Future<void> markUserNotificationAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notificaciones')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> addDoctorNotification({
    required String doctorId,
    required String patientId,
    required String patientName,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    await addNotificationToUser(
      uid: doctorId,
      title: title,
      body: '$patientName: $body',
      type: type,
      extraData: {
        'patientId': patientId,
        'patientName': patientName,
        ...?extraData,
      },
    );
  }

  Future<void> notifyDoctorMedicationStatus({
    required String patientId,
    required String medicationName,
    required String status,
  }) async {
    final patientDoc = await _db.collection('users').doc(patientId).get();
    final patientData = patientDoc.data() ?? <String, dynamic>{};
    final doctorId = (patientData['doctorId'] as String?)?.trim();
    if (doctorId == null || doctorId.isEmpty) return;

    final patientName =
        ((patientData['nombre'] as String?)?.trim().isNotEmpty ?? false)
            ? (patientData['nombre'] as String).trim()
            : 'Paciente';
    String actionLabel = status;
    if (status == 'NO_TOMADO') {
      actionLabel = 'NO LA TOMÉ';
    } else if (status == 'POSPUESTO') {
      actionLabel = 'POSPONER';
    }

    await addDoctorNotification(
      doctorId: doctorId,
      patientId: patientId,
      patientName: patientName,
      title: 'Alerta de adherencia de medicamento',
      body: '$actionLabel en "$medicationName".',
      type: 'MEDICATION_STATUS_ALERT',
      extraData: {
        'medicationName': medicationName,
        'medicationStatus': status,
      },
    );
  }

  /// Aplica una invitación si existe en /invites/{emailLower}
  /// - Lee invite por email
  /// - Crea/actualiza /users/{uid} con rol y datos
  /// - Borra el invite (según rules)
  ///
  /// Retorna true si aplicó invitación, false si no había.
    /// Aplica una invitación si existe en /invites/{emailLower}
  /// Si onlyPatientRole=true, solo aplica invitaciones con rol "paciente".
  Future<bool> applyInviteIfExists({
    required String uid,
    required String email,
    bool onlyPatientRole = false,
  }) async {
    try {
      final emailLower = email.trim().toLowerCase();
      if (emailLower.isEmpty) return false;

      final inviteRef = _db.collection('invites').doc(emailLower);
      final inviteSnap = await inviteRef.get();
      if (!inviteSnap.exists) return false;

      final invite =
          inviteSnap.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final rolRaw = (invite['rol'] ?? invite['role'] ?? '') as String;
      final rol = rolRaw.trim().toLowerCase();

      if (rol != 'doctor' && rol != 'paciente') return false;

      // Si estamos en registro libre, NO aplicar invitaciones de doctor
      if (onlyPatientRole && rol != 'paciente') {
        return false;
      }

      final userRef = _db.collection('users').doc(uid);
      final existingUser = await userRef.get();
      final existsAlready = existingUser.exists;

      final payload = <String, dynamic>{
        'rol': rol,
        'email': email.trim(),
        'nombre': (invite['nombre'] ?? '') as String,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existsAlready) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      if (rol == 'doctor') {
        payload['especialidad'] = (invite['especialidad'] ?? '') as String;
        payload['cedula'] = (invite['cedula'] ?? '') as String;
        payload['telefono'] = (invite['telefono'] ?? '') as String;
        final fotoUrl = (invite['fotoUrl'] ?? '').toString().trim();
        if (fotoUrl.isNotEmpty) payload['fotoUrl'] = fotoUrl;
      }

      if (rol == 'paciente') {
        final doctorId = (invite['doctorId'] ?? '').toString().trim();
        if (doctorId.isNotEmpty) payload['doctorId'] = doctorId;
      }

      await _db.runTransaction((tx) async {
        tx.set(userRef, payload, SetOptions(merge: true));
        tx.delete(inviteRef);
      });

      return true;
    } catch (e) {
      print("Error aplicando invitación: $e");
      return false;
    }
  }
}