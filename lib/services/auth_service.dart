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
  // CONFIGURACIÓN de invitaciones por correo (Opción A)
  //
  // Cambia esta URL por una que esté en "Authorized domains" de
  // Firebase Console (Authentication → Settings → Authorized domains).
  // Puede ser tu dominio de Firebase Hosting gratuito.
  // ============================================================
  static const String _inviteContinueUrl =
      'https://time4med.web.app/finishSignUp';
  static const String _androidPackageName = 'com.example.app_medica';

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
  //
  // IMPORTANTE: antes de mostrar el selector hacemos signOut() del
  // cliente de Google. Así Google NO reutiliza automáticamente la
  // última cuenta y SIEMPRE muestra el selector de cuentas, dándole
  // al usuario la opción de elegir otra cuenta.
  // ============================================================
  Future<User?> signInWithGoogle() async {
    try {
      // 0. Limpia cualquier sesión previa de Google en el dispositivo
      //    para forzar que aparezca el selector de cuentas.
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // ignorar; si no había sesión previa no pasa nada
      }

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

      // 5. Si es la primera vez, crear su doc en /users con rol "paciente".
      //    Luego intentamos aplicar una invitación pendiente (cambia el rol
      //    si el admin lo invitó como doctor, por ejemplo).
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
        await applyInviteIfExists();
      }

      return user;
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      return null;
    }
  }

  // ============================================================
  // Cerrar sesión (Firebase + Google)
  //
  // Usamos disconnect() (no solo signOut) para REVOCAR el acceso de
  // la cuenta de Google en el dispositivo. Esto garantiza que en el
  // siguiente inicio de sesión aparezca el selector y se pueda elegir
  // OTRA cuenta de Google distinta.
  // ============================================================
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('disconnect() falló, intento signOut(): $e');
      try {
        await _googleSignIn.signOut();
      } catch (e2) {
        debugPrint('signOut() de Google también falló: $e2');
      }
    }
    await _auth.signOut();
  }

  // ============================================================
  // ============  INVITACIONES POR CORREO (OPCIÓN A)  ==========
  // ============================================================

  /// Envía un correo de invitación con un enlace de inicio de sesión
  /// (passwordless / email link). Firebase envía el correo gratis en el
  /// plan Spark — no necesitas Cloud Functions ni servidor propio.
  ///
  /// Flujo recomendado:
  ///   1. El admin crea/actualiza /invites/{emailLower} con el rol asignado.
  ///   2. El admin llama a este método para enviar el correo.
  ///   3. El invitado toca el enlace, abre la app, se completa el login con
  ///      [completarLoginConEnlace], y luego [applyInviteIfExists] le pone
  ///      el rol correcto.
  Future<bool> enviarInvitacionPorCorreo(String email) async {
    final emailTrim = email.trim();
    if (emailTrim.isEmpty) return false;

    final acs = ActionCodeSettings(
      url: '$_inviteContinueUrl?email=$emailTrim',
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      // iOSBundleId: 'com.example.appMedica', // si publicas en iOS
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: emailTrim,
        actionCodeSettings: acs,
      );
      debugPrint('Invitación enviada a $emailTrim');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error enviando invitación: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error enviando invitación: $e');
      return false;
    }
  }

  /// Comprueba si una URL recibida (al abrir la app desde el correo) es un
  /// enlace válido de inicio de sesión por email.
  bool esEnlaceDeInicioSesion(String emailLink) {
    return _auth.isSignInWithEmailLink(emailLink);
  }

  /// Completa el inicio de sesión usando el enlace recibido por correo.
  /// [email] es el correo al que se envió la invitación (puedes recuperarlo
  /// del query param ?email= del enlace, o pedirlo al usuario).
  ///
  /// Tras autenticar, crea el doc /users si no existe y aplica la invitación.
  Future<User?> completarLoginConEnlace(
      {required String email, required String emailLink}) async {
    final emailTrim = email.trim();
    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        debugPrint('El enlace no es un sign-in link válido.');
        return null;
      }

      final UserCredential cred = await _auth.signInWithEmailLink(
        email: emailTrim,
        emailLink: emailLink,
      );
      final User? user = cred.user;

      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'nombre': user.displayName ?? '',
            'email': user.email ?? emailTrim,
            'rol': 'paciente',
            'fechaRegistro': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await applyInviteIfExists();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al completar login con enlace: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error al completar login con enlace: $e');
      return null;
    }
  }

  /// Aplica una invitación pendiente para el usuario autenticado:
  /// busca /invites/{emailLower}, y si existe, asigna el rol invitado
  /// al doc del usuario y borra el invite.
  Future<bool> applyInviteIfExists() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    final emailLower = user.email!.toLowerCase();
    final inviteRef = _db.collection('invites').doc(emailLower);

    try {
      final inviteSnap = await inviteRef.get();
      if (!inviteSnap.exists) return false;

      final invite = inviteSnap.data() ?? <String, dynamic>{};
      final rol = (invite['rol'] ?? invite['role'] ?? '') as String;

      if (rol.isNotEmpty) {
        await _db.collection('users').doc(user.uid).set({
          'rol': rol,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Borrar el invite ya aplicado (las reglas permiten al dueño borrarlo).
      await inviteRef.delete();
      return true;
    } catch (e) {
      debugPrint('Error aplicando invitación: $e');
      return false;
    }
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