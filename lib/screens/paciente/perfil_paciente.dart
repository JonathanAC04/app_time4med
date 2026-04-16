import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilPaciente extends StatelessWidget {
  const PerfilPaciente({Key? key}) : super(key: key);

  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () {}),
        title: const Text("Perfil del Usuario", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black), onPressed: () {})],
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
                const Text("Ver Todo", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
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
                  IconButton(icon: const Icon(Icons.phone_outlined, color: Color(0xFFFF4C79)), onPressed: () {}),
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
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 30),

            // Botón Cerrar Sesión
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () => _cerrarSesion(context),
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