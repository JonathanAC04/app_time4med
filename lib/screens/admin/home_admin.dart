import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'doctores_admin_view.dart';
import 'pacientes_admin_view.dart';
import 'invitaciones_admin_view.dart';

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

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cerrar sesión",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Cerrar sesión",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return _buildManagementTab();
    }
    if (_selectedIndex == 2) {
      return _buildSettingsTab();
    }
    return _buildDashboardTab();
  }

  Widget _buildDashboardTab() {
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B5DE8)))
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
        ],
      ),
    );
  }

  Widget _buildManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestión",
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
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PacientesAdminView()),
            ),
          ),
          _buildBotonAccion(
            Icons.mark_email_unread_outlined,
            "Invitaciones",
            "Asigna un rol a un correo por adelantado",
            Colors.deepOrange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvitacionesAdminView()),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PESTAÑA DE CONFIGURACIÓN (mejorada)
  // =====================================================================
  Widget _buildSettingsTab() {
    final adminEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Administrador';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ---- Tarjeta de perfil del admin ----
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B5DE8), Color(0xFF8A7DF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Administrador',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminEmail,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---- Resumen rápido ----
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Doctores', '$_totalDoctores',
                  Icons.medical_services_outlined, Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Pacientes', '$_totalPacientes',
                  Icons.groups_outlined, const Color(0xFF6B5DE8)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Gestión',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        _buildBotonAccion(
          Icons.medical_services_outlined,
          'Doctores',
          'Ver, crear y editar doctores',
          Colors.teal,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctoresAdminView()),
          ),
        ),
        _buildBotonAccion(
          Icons.groups_outlined,
          'Pacientes',
          'Ver, crear y asignar pacientes',
          const Color(0xFF6B5DE8),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PacientesAdminView()),
          ),
        ),
        _buildBotonAccion(
          Icons.mark_email_unread_outlined,
          'Invitaciones',
          'Asigna un rol a un correo por adelantado',
          Colors.deepOrange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvitacionesAdminView()),
          ),
        ),

        const SizedBox(height: 20),
        const Text('Información',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF6B5DE8)),
                  SizedBox(width: 10),
                  Text('Time4Med',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              SizedBox(height: 8),
              Text('Versión 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                'Gestión de medicamentos y citas médicas. '
                'Desde este panel administras doctores y pacientes.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ---- Cerrar sesión ----
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: _cerrarSesion,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatCard(
      String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icono, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBotonAccion(IconData icono, String titulo, String subtitulo,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitulo,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), label: "Panel"),
        BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined), label: "Gestión"),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined), label: "Configuración"),
      ],
    );
  }
}