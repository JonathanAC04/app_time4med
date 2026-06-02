import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

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
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _registrar() async {
    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar los términos"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nombreCompleto =
          "${_nombreController.text.trim()} ${_apellidoController.text.trim()}".trim();

      final user = await _authService.register(
        email,
        password,
        nombreCompleto,
        "paciente", // registro libre -> paciente
      );

      if (!mounted) return;

      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al crear cuenta"), backgroundColor: Colors.red),
        );
        return;
      }

      // Si existe invitación y es de PACIENTE, la aplicamos. Si es de DOCTOR, NO.
      await _firestoreService.applyInviteIfExists(
        uid: user.uid,
        email: email,
        onlyPatientRole: true,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/paciente');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _registrarConGoogle() async {
    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar los términos"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (user == null) {
        setState(() => _isLoading = false);
        return; // El usuario canceló la autenticación con Google
      }

      final email = user.email;
      if (email != null && email.trim().isNotEmpty) {
        // En registro libre siempre va a paciente a menos que haya una invitación de paciente
        await _firestoreService.applyInviteIfExists(
          uid: user.uid,
          email: email,
          onlyPatientRole: true, // Sólo aplicar si es paciente
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/paciente');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
            const Text(
              "Únete a miles de usuarios y haz de tomar tus medicamentos una actividad más sencilla.",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(child: _buildTextField("Nombre", "Ej. Juan", Icons.person_outline, _nombreController)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Apellido", "Ej. Pérez", Icons.person_outline, _apellidoController)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField("Correo electrónico", "juan.perez@ejemplo.com", Icons.email_outlined, _emailController),
            const SizedBox(height: 15),
            _buildTextField("Contraseña", "••••••••", Icons.lock_outline, _passwordController, isPassword: true),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _aceptaTerminos,
                  onChanged: (val) => setState(() => _aceptaTerminos = val ?? false),
                  activeColor: const Color(0xFF6B5DE8),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Acepto los Términos de Servicio y la Política de Privacidad de Time4med.",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5DE8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _registrar,
                      child: const Text("Crear cuenta", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    String? subtext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 5),
          Text(subtext, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]
      ],
    );
  }
}