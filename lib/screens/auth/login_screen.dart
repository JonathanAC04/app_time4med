import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _iniciarSesion() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Revisa tus credenciales"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 1) Aplicar invitación si existe (antes de leer rol)
      final email = user.email;
      if (email != null && email.trim().isNotEmpty) {
        await _firestoreService.applyInviteIfExists(uid: user.uid, email: email);
      }

      if (!mounted) return;

      // 2) Ya con la invitación aplicada, leemos rol
      final rol = await _firestoreService.getUserRole(user.uid);

      if (!mounted) return;

      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (rol == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor');
      } else if (rol == 'paciente') {
        Navigator.pushReplacementNamed(context, '/paciente');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No tienes rol asignado. Contacta al administrador."),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ocurrió un error: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _iniciarSesionGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (user == null) {
        setState(() => _isLoading = false);
        return; // El usuario canceló la autenticación con Google
      }

      // Aplicar invitación si existe (antes de leer rol)
      final email = user.email;
      if (email != null && email.trim().isNotEmpty) {
        await _firestoreService.applyInviteIfExists(uid: user.uid, email: email);
      }

      if (!mounted) return;

      final rol = await _firestoreService.getUserRole(user.uid);

      if (!mounted) return;

      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (rol == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor');
      } else if (rol == 'paciente') {
        Navigator.pushReplacementNamed(context, '/paciente');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No tienes rol asignado. Contacta al administrador."),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error de inicio de sesión con Google: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Center(
                child: Icon(
                  Icons.monitor_heart,
                  size: 80,
                  color: Color(0xFF6B5DE8),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Time 4 med",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text("Correo electrónico",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Ej. juan@ejemplo.com",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Contraseña",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B5DE8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _iniciarSesion,
                        child: const Text(
                          "Iniciar sesión",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        icon: Image.network(
                          'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                          height: 24,
                        ),
                        onPressed: _iniciarSesionGoogle,
                        label: const Text(
                          "Iniciar sesión con Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta? ",
                      style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Regístrate aquí",
                      style: TextStyle(
                        color: Color(0xFF6B5DE8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}