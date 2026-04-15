import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _rolSeleccionado = 'paciente'; // Por defecto

  void _registrarUsuario() async {
    setState(() => _isLoading = true);

    var user = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nombreController.text.trim(),
      _rolSeleccionado,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      // Si se registró bien, lo mandamos a su pantalla correspondiente
      if (_rolSeleccionado == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor');
      } else {
        Navigator.pushReplacementNamed(context, '/paciente');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar. Revisa los datos."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Crear Cuenta"), backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Únete a la app", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: "Nombre completo", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: "Correo electrónico", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Contraseña (mínimo 6 letras)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 15),
            Text("¿Qué tipo de usuario eres?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            SizedBox(height: 5),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _rolSeleccionado,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'paciente', child: Text("Soy Paciente")),
                    DropdownMenuItem(value: 'doctor', child: Text("Soy Doctor/a")),
                  ],
                  onChanged: (value) => setState(() => _rolSeleccionado = value!),
                ),
              ),
            ),
            SizedBox(height: 30),
            _isLoading 
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6B5DE8), padding: EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _registrarUsuario,
                  child: Text("Registrarme", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
          ],
        ),
      ),
    );
  }
}