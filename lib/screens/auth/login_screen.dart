import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final authService = AuthService();
  final firestoreService = FirestoreService();
  
  bool _isLoading = false;

  void _iniciarSesion() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Intentar loguear en Firebase Auth
    var user = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      // 2. Si el login es correcto, buscar su rol en Firestore
      String? rol = await firestoreService.getUserRole(user.uid);

      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (rol == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor');
      } else if (rol == 'paciente') {
        Navigator.pushReplacementNamed(context, '/paciente');
      } else {
        _mostrarError("Usuario sin rol asignado");
      }
    } else {
      _mostrarError("Correo o contraseña incorrectos");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 25),
            _isLoading 
              ? CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: _iniciarSesion,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    child: Text("Entrar", style: TextStyle(fontSize: 16)),
                    
                  ),
                ),
                // ... tu botón de Entrar actual ...
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text("¿No tienes cuenta? Regístrate aquí", style: TextStyle(color: Color(0xFF6B5DE8))),
                ),
          ],
        ),
      ),
    );
  }
}