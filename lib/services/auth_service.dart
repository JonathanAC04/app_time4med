import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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

  Future<String> createUserFromAdmin({
    required String email,
    required String password,
  }) async {
    final appName = 'admin-create-${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'No se pudo crear el usuario.',
        );
      }
      await secondaryAuth.signOut();
      return user.uid;
    } finally {
      await secondaryApp.delete();
    }
  }
}
