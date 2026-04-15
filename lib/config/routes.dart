import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart'; // <-- Agrega esta línea
import '../screens/paciente/home_paciente.dart';
import '../screens/doctor/home_doctor.dart';
import '../screens/admin/home_admin.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (context) => LoginScreen(),
    '/register': (context) => RegisterScreen(), // <-- Agrega esta línea
    '/paciente': (context) => HomePaciente(),
    '/doctor': (context) => HomeDoctor(),
    '/admin': (context) => HomeAdmin(),
  };
}