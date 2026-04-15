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
}