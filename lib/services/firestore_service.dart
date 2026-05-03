import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<void> addMedicamento(
      String uid, String nombre, String dosis, DateTime fechaHora) async {
    final fecha =
        "${fechaHora.year.toString().padLeft(4, '0')}-${fechaHora.month.toString().padLeft(2, '0')}-${fechaHora.day.toString().padLeft(2, '0')}";
    final hora =
        "${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}";
    await _db.collection('users').doc(uid).collection('medicamentos').add({
      'nombre': nombre,
      'dosis': dosis,
      'hora': hora,
      'fecha': fecha,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'status': 'PENDIENTE',
      'creado': FieldValue.serverTimestamp(),
    });
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