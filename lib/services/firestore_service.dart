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
        return doc['rol']; // Devuelve 'admin', 'doctor' o 'paciente'
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
    final docRef = await _db.collection('users').doc(uid).collection('medicamentos').add({
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
  Stream<QuerySnapshot> getMedicamentosStream(String uid) {
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
      'hora': '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
      'fechaHora': Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute)),
      'motivo': motivo,
      'creado': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Stream en tiempo real de las citas del paciente (ordenadas por fechaHora)
  Stream<QuerySnapshot> getCitasStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('citas')
        .orderBy('fechaHora', descending: false)
        .snapshots();
  }

  Future<QuerySnapshot> getMedicamentosOnce(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('medicamentos')
        .orderBy('creado', descending: false)
        .get();
  }

  Future<QuerySnapshot> getCitasOnce(String uid) {
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
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
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
}
