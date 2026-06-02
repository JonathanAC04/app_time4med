import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ============================================================
  // Login con email y contraseña
  // ============================================================
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      debugPrint("Error en Login: $e");
      return null;
    }
  }

  // ============================================================
  // Registro con email y contraseña
  // ============================================================
  Future<User?> register(
      String email, String password, String nombre, String rol) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'nombre': nombre,
          'email': email,
          'rol': rol,
          'fechaRegistro': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      debugPrint("Error en Registro: $e");
      return null;
    }
  }

  // ============================================================
  // Google Sign-In (API v6)
  // ============================================================
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Mostrar selector de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si el usuario cierra el selector sin elegir cuenta
      if (googleUser == null) {
        debugPrint('Usuario canceló el login con Google.');
        return null;
      }

      // 2. Obtener tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Construir la credencial para Firebase Auth
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con esa credencial
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // 5. Si es la primera vez, crear su doc en /users con rol "paciente"
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'nombre': user.displayName ?? '',
            'email': user.email,
            'rol': 'paciente',
            'fechaRegistro': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      return null;
    }
  }

  // ============================================================
  // Cerrar sesión (Firebase + Google)
  // ============================================================
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error en signOut de Google: $e');
    }
    await _auth.signOut();
  }

  // ============================================================
  // createUserFromAdmin: usa una FirebaseApp secundaria para que
  // el admin no pierda su sesión al crear pacientes/doctores.
  // ============================================================
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
      debugPrint('createUserFromAdmin auth error: ${e.code} ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('createUserFromAdmin firestore error: ${e.code} ${e.message}');
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (deleteError) {
          debugPrint('Rollback failed: $deleteError');
        }
      }
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }
}