import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'editar_paciente_view.dart';

class PerfilPaciente extends StatefulWidget {
  const PerfilPaciente({Key? key}) : super(key: key);

  @override
  _PerfilPacienteState createState() => _PerfilPacienteState();
}

class _PerfilPacienteState extends State<PerfilPaciente> {
  // true = assigned by a doctor, false = manual registration
  bool _esAsignado = false;
  bool _tieneFoto = true;

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

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cerrar sesión",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "¿Estás seguro de que deseas cerrar sesión?",
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Cerrar sesión",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _abrirMenuFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Foto de perfil",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_a_photo_outlined,
                    color: Color(0xFF6B5DE8), size: 24),
              ),
              title: const Text("Añadir nueva foto de perfil",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _tieneFoto = true);
                _showSnackBar("📷 Función de cámara próximamente disponible.");
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFFF4C79), size: 24),
              ),
              title: const Text("Borrar foto de perfil",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF4C79))),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _tieneFoto = false);
                _showSnackBar("🗑️ Foto de perfil eliminada.");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirAjustes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ajustes",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAjusteTile(Icons.notifications_outlined, "Notificaciones",
                "Gestionar alertas de medicamentos", () {
              Navigator.pop(ctx);
              _showSnackBar("Notificaciones: próximamente configurable.");
            }),
            _buildAjusteTile(Icons.lock_outline, "Privacidad y seguridad",
                "Cambiar contraseña y permisos", () {
              Navigator.pop(ctx);
              _showSnackBar("Privacidad: próximamente configurable.");
            }),
            _buildAjusteTile(
                Icons.language_outlined, "Idioma", "Español", () {
              Navigator.pop(ctx);
              _showSnackBar("Idioma: próximamente configurable.");
            }),
            _buildAjusteTile(
                Icons.help_outline, "Ayuda y soporte", "Preguntas frecuentes",
                () {
              Navigator.pop(ctx);
              _showSnackBar("Soporte: próximamente disponible.");
            }),
          ],
        ),
      ),
    );
  }

  ListTile _buildAjusteTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF6B5DE8)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _irAEditarPaciente() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditarPacienteView()),
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
        title: const Text("Perfil del Usuario",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            // --- Foto de perfil con etiqueta ---
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _abrirMenuFoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE8E5FF),
                          backgroundImage: _tieneFoto
                              ? const NetworkImage(
                                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80')
                              : null,
                          child: !_tieneFoto
                              ? const Icon(Icons.person,
                                  color: Color(0xFF6B5DE8), size: 50)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5DE8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Alejandro González",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Etiqueta: Asignado o sin etiqueta
                  if (_esAsignado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        border: Border.all(
                            color: Colors.green.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: Colors.green.shade600, size: 14),
                          const SizedBox(width: 4),
                          Text("ASIGNADO",
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Sección: Datos del Paciente ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DATOS DEL PACIENTE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2)),
                GestureDetector(
                  onTap: _irAEditarPaciente,
                  child: const Text("Ver Todo",
                      style: TextStyle(
                          color: Color(0xFF6B5DE8),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildDatosGrid(),
            const SizedBox(height: 30),

            // --- Sección: Seguridad ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("SEGURIDAD",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2)),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFFF4C79), size: 30),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Contacto de Emergencia",
                            style: TextStyle(
                                color: Color(0xFFFF4C79),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        Text("María G. (Esposa)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("+34 600 123 456",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined,
                        color: Color(0xFFFF4C79)),
                    onPressed: () =>
                        _showSnackBar("📞 Llamando a contacto de emergencia..."),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- Botón Editar Información Personal ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                label: const Text("Editar Información Personal",
                    style: TextStyle(color: Colors.black87, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    side: BorderSide(color: Colors.grey.shade300)),
                onPressed: _irAEditarPaciente,
              ),
            ),
            const SizedBox(height: 30),

            // --- Botón Cerrar Sesión ---
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Cerrar Sesión",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                onPressed: _confirmarCerrarSesion,
              ),
            ),
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
            Expanded(
                child: _buildDatoCard(
                    Icons.calendar_month, "NACIMIENTO", "12 Mayo\n1988")),
            const SizedBox(width: 15),
            Expanded(
                child: _buildDatoCard(
                    Icons.person_outline, "GÉNERO", "Masculino")),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
                child: _buildDatoCard(
                    Icons.water_drop_outlined, "SANGRE", "O Positivo\n(+)")),
            const SizedBox(width: 15),
            Expanded(
                child:
                    _buildDatoCard(Icons.scale_outlined, "PESO", "78.5 kg")),
          ],
        ),
      ],
    );
  }

  Widget _buildDatoCard(IconData icon, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF6B5DE8), size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(valor,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
