import 'package:flutter/material.dart';

class HomeAdmin extends StatefulWidget {
  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estadísticas del Sistema", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            _buildEstadisticasGrid(),
            SizedBox(height: 30),
            Text("Acciones Rápidas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            _buildBotonAccion(Icons.person_add_alt_1, "Registrar Nuevo Doctor", Colors.blueGrey),
            _buildBotonAccion(Icons.assignment_ind, "Asignar Pacientes", Colors.blueGrey),
            _buildBotonAccion(Icons.bar_chart, "Ver Reportes Generales", Colors.blueGrey),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueGrey.shade900,
      elevation: 0,
      title: Text("Administración", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ],
    );
  }

  Widget _buildEstadisticasGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildStatCard("Doctores", "45", Icons.medical_services, Colors.teal),
              SizedBox(height: 15),
              _buildStatCard("Alertas", "3", Icons.error_outline, Colors.redAccent),
            ],
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildStatCard("Pacientes Activos", "1,204", Icons.groups, Colors.indigo, altura: 175),
        ),
      ],
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color, {double altura = 80}) {
    return Container(
      height: altura,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, color: color, size: 28),
              if (altura > 80) Text(valor, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          if (altura <= 80) Spacer(),
          if (altura > 80) Spacer(),
          if (altura <= 80) Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          if (altura > 80) Text(titulo, style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBotonAccion(IconData icono, String texto, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300)
        ),
        onPressed: () {},
        child: Row(
          children: [
            Icon(icono, size: 24),
            SizedBox(width: 15),
            Text(texto, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: Colors.blueGrey.shade900,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Panel"),
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: "Usuarios"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
      ],
    );
  }
}