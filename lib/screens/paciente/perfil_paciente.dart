import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilPaciente extends StatefulWidget {
  const PerfilPaciente({Key? key}) : super(key: key);

  @override
  _PerfilPacienteState createState() => _PerfilPacienteState();
}

class _PerfilPacienteState extends State<PerfilPaciente> {
  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6B5DE8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _abrirAjustes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ajustes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAjusteTile(Icons.notifications_outlined, "Notificaciones", "Gestionar alertas de medicamentos", () {
              Navigator.pop(ctx);
              _showSnackBar("Notificaciones: próximamente configurable.");
            }),
            _buildAjusteTile(Icons.lock_outline, "Privacidad y seguridad", "Cambiar contraseña y permisos", () {
              Navigator.pop(ctx);
              _showSnackBar("Privacidad: próximamente configurable.");
            }),
            _buildAjusteTile(Icons.language_outlined, "Idioma", "Español (España)", () {
              Navigator.pop(ctx);
              _showSnackBar("Idioma: próximamente configurable.");
            }),
            _buildAjusteTile(Icons.help_outline, "Ayuda y soporte", "Preguntas frecuentes", () {
              Navigator.pop(ctx);
              _showSnackBar("Soporte: próximamente disponible.");
            }),
          ],
        ),
      ),
    );
  }

  ListTile _buildAjusteTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF6B5DE8)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _abrirEditarPerfil() {
    final nombreController = TextEditingController(text: "Alejandro González");
    final telefonoController = TextEditingController(text: "+34 600 123 456");
    final pesoController = TextEditingController(text: "78.5");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Editar Perfil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: "Nombre completo", prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Teléfono de contacto", prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Peso (kg)", prefixIcon: Icon(Icons.scale_outlined), suffixText: "kg"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5DE8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showSnackBar("✅ Perfil actualizado correctamente.");
                },
                child: const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("Perfil del Usuario", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: _abrirAjustes,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Foto de perfil y VIP
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF6B5DE8), width: 2), borderRadius: BorderRadius.circular(15)),
                    child: const Text("VIP", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, fontSize: 10)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text("Alejandro González", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 35),

            // Sección: Datos del Paciente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DATOS DEL PACIENTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                GestureDetector(
                  onTap: () => _showSnackBar("Mostrando todos los datos del paciente."),
                  child: const Text("Ver Todo", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildDatosGrid(),
            const SizedBox(height: 30),

            // Sección: Seguridad
            const Align(alignment: Alignment.centerLeft, child: Text("SEGURIDAD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2))),
            const SizedBox(height: 15),

            // Tarjeta de Emergencia
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF4C79), size: 30),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Contacto de Emergencia", style: TextStyle(color: Color(0xFFFF4C79), fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("María G. (Esposa)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("+34 600 123 456", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, color: Color(0xFFFF4C79)),
                    onPressed: () => _showSnackBar("📞 Llamando a contacto de emergencia..."),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Botón Editar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                label: const Text("Editar Información Personal", style: TextStyle(color: Colors.black87, fontSize: 16)),
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), side: BorderSide(color: Colors.grey.shade300)),
                onPressed: _abrirEditarPerfil,
              ),
            ),
            const SizedBox(height: 30),

            // Botón Cerrar Sesión
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _cerrarSesion,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDatosGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDatoCard(Icons.calendar_month, "NACIMIENTO", "12 Mayo\n1988")),
            const SizedBox(width: 15),
            Expanded(child: _buildDatoCard(Icons.person_outline, "GÉNERO", "Masculino")),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildDatoCard(Icons.water_drop_outlined, "SANGRE", "O Positivo\n(+)")),
            const SizedBox(width: 15),
            Expanded(child: _buildDatoCard(Icons.scale_outlined, "PESO", "78.5 kg")),
          ],
        ),
      ],
    );
  }

  Widget _buildDatoCard(IconData icon, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF6B5DE8), size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}