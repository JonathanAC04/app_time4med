import 'package:flutter/material.dart';

class HomeDoctor extends StatefulWidget {
  @override
  _HomeDoctorState createState() => _HomeDoctorState();
}

class _HomeDoctorState extends State<HomeDoctor> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resumen General", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            _buildResumenTarjetas(),
            SizedBox(height: 30),
            Text("Tus Pacientes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            _buildPacienteCard("Juan Pérez", "Adherencia: 85%", "Tratamiento activo", Colors.green),
            _buildPacienteCard("María López", "Adherencia: 40%", "Faltan tomas recientes", Colors.redAccent),
            _buildPacienteCard("Carlos Ruiz", "Adherencia: 100%", "Excelente progreso", Colors.green),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.person_add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hola, Dr(a).", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text("Panel Médico", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'), // Botón rápido para salir y probar otros roles
        ),
      ],
    );
  }

  Widget _buildResumenTarjetas() {
    return Row(
      children: [
        Expanded(child: _buildInfoCard("Pacientes", "12", Icons.people, Colors.blueAccent)),
        SizedBox(width: 15),
        Expanded(child: _buildInfoCard("Alertas", "2", Icons.warning_amber_rounded, Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildInfoCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 30),
          SizedBox(height: 10),
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(titulo, style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPacienteCard(String nombre, String adherencia, String estado, Color colorEstado) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(Icons.person, color: Colors.blueAccent)),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text(adherencia, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(estado, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Pacientes"),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Mensajes"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
      ],
    );
  }
}