import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Asegúrate de importar esto
import 'config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Médica',
      initialRoute: '/login',
      routes: AppRoutes.routes,
    );
  }
}