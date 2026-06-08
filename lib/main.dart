import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config/routes.dart';
import 'services/local_notification_service.dart';

// Pantallas destino según rol (ajusta las rutas si tus archivos difieren)
import 'screens/auth/login_screen.dart';
import 'screens/admin/home_admin.dart';
import 'screens/doctor/home_doctor.dart';
import 'screens/paciente/home_paciente.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time 4 med',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6B5DE8),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF6B5DE8), width: 2),
          ),
        ),
      ),
      // En vez de ir siempre a /login, el AuthGate decide a dónde ir.
      home: const AuthGate(),
      routes: AppRoutes.routes,
    );
  }
}

/// Decide la pantalla inicial según la sesión activa y el rol del usuario.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Esperando a saber si hay sesión.
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashCargando();
        }

        final user = authSnap.data;

        // No hay sesión → login.
        if (user == null) {
          return const LoginScreen();
        }

        // Hay sesión → leer el rol desde Firestore para enrutar.
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future:
              FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _SplashCargando();
            }

            final data = userSnap.data?.data();

            // Si por alguna razón no existe el doc, lo mandamos al login.
            if (data == null) {
              return const LoginScreen();
            }

            final rol = (data['rol'] as String?) ?? 'paciente';

            switch (rol) {
              case 'admin':
                return const HomeAdmin();
              case 'doctor':
                return const HomeDoctor();
              case 'paciente':
              default:
                return const HomePaciente();
            }
          },
        );
      },
    );
  }
}

/// Pantalla de carga mientras se resuelve la sesión.
class _SplashCargando extends StatelessWidget {
  const _SplashCargando({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_rounded,
                size: 64, color: Color(0xFF6B5DE8)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFF6B5DE8)),
          ],
        ),
      ),
    );
  }
}