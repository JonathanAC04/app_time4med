import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'doctores_admin_view.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({Key? key}) : super(key: key);

  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  int _totalDoctores = 0;
  int _totalPacientes = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final doctores = await _firestoreService.countUsersByRole('doctor');
    final pacientes = await _firestoreService.countUsersByRole('paciente');
    if (mounted) {
      setState(() {
        _totalDoctores = doctores;
        _totalPacientes = pacientes;
        _loadingStats = false;
      });
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF6B5DE8),
      elevation: 0,
      title: const Text(
        "Panel de Administración",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: "Cerrar sesión",
          onPressed: _cerrarSesion,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen del sistema
          const Text(
            "Resumen del Sistema",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _loadingStats
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)))
              : Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Doctores",
                        _totalDoctores.toString(),
                        Icons.medical_services_outlined,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        "Pacientes",
                        _totalPacientes.toString(),
                        Icons.groups_outlined,
                        const Color(0xFF6B5DE8),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 30),

          // Opciones principales
          const Text(
            "Administración",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildBotonAccion(
            Icons.medical_services_outlined,
            "Administrar Doctores",
            "Gestiona el equipo médico",
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctoresAdminView()),
            ),
          ),
          _buildBotonAccion(
            Icons.groups_outlined,
            "Administrar Pacientes",
            "Gestiona los pacientes registrados",
            const Color(0xFF6B5DE8),
            () {},
          ),
          _buildBotonAccion(
            Icons.bar_chart_outlined,
            "Ver Reportes Generales",
            "Estadísticas y métricas del sistema",
            Colors.indigo,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icono, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBotonAccion(IconData icono, String titulo, String subtitulo, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: const Color(0xFF6B5DE8),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Panel"),
        BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_outlined), label: "Usuarios"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Ajustes"),
      ],
    );
  }
}