import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // 3. Iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Verificar si es la primera vez que inicia sesión (no existe en users)
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'nombre': user.displayName ?? '',
            'email': user.email,
            'rol': 'paciente', // Por defecto "paciente"
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      return null;
    }
  }

  Future<String> createUserFromAdmin({
    required String email,
    required String password,
    Map<String, dynamic>? profileData,
  }) async {
    final appName = 'admin-create-${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: Firebase.app().options,
    );
    User? createdUser;
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'No se pudo crear el usuario.',
        );
      }
      if (profileData != null) {
        await _db.collection('users').doc(createdUser.uid).set(
              profileData,
              SetOptions(merge: true),
            );
      }
      await secondaryAuth.signOut();
      return createdUser.uid;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.createUserFromAdmin auth error: ${e.code} ${e.message}');
      }
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.createUserFromAdmin firestore error: ${e.code} ${e.message}');
      }
      if (createdUser != null) {
        try {
          await createdUser!.delete();
          if (kDebugMode) {
            debugPrint('AuthService.createUserFromAdmin rollback: auth user deleted for ${createdUser!.uid}');
          }
        } catch (deleteError) {
          if (kDebugMode) {
            debugPrint('AuthService.createUserFromAdmin rollback failed: $deleteError');
          }
        }
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.createUserFromAdmin unexpected error: $e');
      }
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }
}
