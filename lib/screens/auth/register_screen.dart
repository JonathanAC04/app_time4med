import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  bool _aceptaTerminos = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  void _registrar() async {
    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes aceptar los términos"), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);

    var user = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      "${_nombreController.text} ${_apellidoController.text}",
      "paciente", // Registramos como paciente por defecto
    );

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/paciente');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al crear cuenta"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart, color: Colors.black),
            SizedBox(width: 8),
            Text("Time 4 med", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(20)),
              child: const Text("Paso 1 de 1", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 15),
            const Text("Crea tu cuenta", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Únete a miles de usuarios y haz de tomar tus medicamentos una actividad más sencilla.", style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(child: _buildTextField("Nombre", "Ej. Juan", Icons.person_outline, _nombreController)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Apellido", "Ej. Pérez", Icons.person_outline, _apellidoController)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField("Correo electrónico", "juan.perez@ejemplo.com", Icons.email_outlined, _emailController, subtext: "Usaremos esto para enviarte confirmaciones."),
            const SizedBox(height: 15),
            _buildTextField("Contraseña", "••••••••", Icons.lock_outline, _passwordController, isPassword: true, subtext: "Mínimo 6 caracteres."),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: _aceptaTerminos, onChanged: (val) => setState(() => _aceptaTerminos = val!), activeColor: const Color(0xFF6B5DE8)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text("Acepto los Términos de Servicio y la Política de Privacidad de Time4med.", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _registrar,
                      child: const Text("Crear cuenta", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Ahora SÍ recibe el controlador para guardar lo que escribes
  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isPassword = false, String? subtext}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400), prefixIcon: Icon(icon, color: Colors.grey)),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 5),
          Text(subtext, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]
      ],
    );
  }
}