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

  // Agrega un medicamento a la subcolección del paciente
  Future<void> addMedicamento(String uid, String nombre, String dosis, String hora) async {
    await _db.collection('users').doc(uid).collection('medicamentos').add({
      'nombre': nombre,
      'dosis': dosis,
      'hora': hora,
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