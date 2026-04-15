import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Iniciar sesión (Ya lo tenías)
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Error en Login: $e");
      return null;
    }
  }

  // 2. NUEVO: Registrar usuario y guardar su rol en la base de datos
  Future<User?> register(String email, String password, String nombre, String rol) async {
    try {
      // A) Crea el usuario en Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // B) Guarda su información y su ROL en Firestore Database
        await _db.collection('users').doc(user.uid).set({
          'nombre': nombre,
          'email': email,
          'rol': rol,
          'fechaRegistro': DateTime.now(),
        });
      }
      return user;
    } catch (e) {
      print("Error en Registro: $e");
      return null;
    }
  }
}