import 'package:flutter/material.dart';
import 'detalle_paciente_view.dart';

// Modelo simple de Paciente para la UI
class PacienteModel {
  final String id;
  final String nombre;
  final String dni;
  final String email;
  final String genero;
  final int edad;
  final String estado; // 'activo', 'inactivo', 'eliminado'
  final String iniciales;
  final Color avatarColor;

  const PacienteModel({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.email,
    required this.genero,
    required this.edad,
    required this.estado,
    required this.iniciales,
    required this.avatarColor,
  });
}

// Datos de muestra
final List<PacienteModel> _pacientesMuestra = [
  const PacienteModel(id: '1', nombre: 'María García', dni: '12345678A', email: 'maria.garcia@email.com', genero: 'Femenino', edad: 34, estado: 'activo', iniciales: 'MG', avatarColor: Color(0xFF6B5DE8)),
  const PacienteModel(id: '2', nombre: 'Carlos López', dni: '87654321B', email: 'carlos.lopez@email.com', genero: 'Masculino', edad: 45, estado: 'activo', iniciales: 'CL', avatarColor: Colors.teal),
  const PacienteModel(id: '3', nombre: 'Ana Rodríguez', dni: '11223344C', email: 'ana.rodriguez@email.com', genero: 'Femenino', edad: 28, estado: 'inactivo', iniciales: 'AR', avatarColor: Colors.orange),
  const PacienteModel(id: '4', nombre: 'Luis Martínez', dni: '44332211D', email: 'luis.martinez@email.com', genero: 'Masculino', edad: 60, estado: 'activo', iniciales: 'LM', avatarColor: Colors.indigo),
  const PacienteModel(id: '5', nombre: 'Sofía Hernández', dni: '55667788E', email: 'sofia.hernandez@email.com', genero: 'Femenino', edad: 22, estado: 'eliminado', iniciales: 'SH', avatarColor: Colors.pink),
];

class PacientesAdminView extends StatefulWidget {
  const PacientesAdminView({Key? key}) : super(key: key);

  @override
  _PacientesAdminViewState createState() => _PacientesAdminViewState();
}

class _PacientesAdminViewState extends State<PacientesAdminView> {
  final TextEditingController _searchController = TextEditingController();
  List<PacienteModel> _pacientesFiltrados = _pacientesMuestra;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarPacientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarPacientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _pacientesFiltrados = _pacientesMuestra
          .where((p) =>
              p.nombre.toLowerCase().contains(query) ||
              p.dni.toLowerCase().contains(query))
          .toList();
    });
  }

  int get _totalActivos => _pacientesMuestra.where((p) => p.estado == 'activo').length;
  int get _totalInactivos => _pacientesMuestra.where((p) => p.estado == 'inactivo').length;
  int get _totalEliminados => _pacientesMuestra.where((p) => p.estado == 'eliminado').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B5DE8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Gestión de Pacientes",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Encabezado con gradiente y estadísticas
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B5DE8), Color(0xFF9B8BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                // Estadísticas
                Row(
                  children: [
                    _buildStatBadge("Total", _pacientesMuestra.length.toString(), Icons.groups_outlined, Colors.white),
                    const SizedBox(width: 8),
                    _buildStatBadge("Activos", _totalActivos.toString(), Icons.check_circle_outline, Colors.greenAccent),
                    const SizedBox(width: 8),
                    _buildStatBadge("Inactivos", _totalInactivos.toString(), Icons.pause_circle_outline, Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _buildStatBadge("Eliminados", _totalEliminados.toString(), Icons.delete_outline, Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 16),
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Buscar paciente o DNI...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B5DE8)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de pacientes
          Expanded(
            child: _pacientesFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      "No se encontraron pacientes",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _pacientesFiltrados.length,
                    itemBuilder: (context, index) {
                      return _buildPacienteCard(_pacientesFiltrados[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Función: Nuevo Paciente (próximamente)"),
              backgroundColor: Color(0xFF6B5DE8),
            ),
          );
        },
        backgroundColor: const Color(0xFF6B5DE8),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text("Nuevo Paciente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPacienteCard(PacienteModel paciente) {
    final bool activo = paciente.estado == 'activo';
    final bool eliminado = paciente.estado == 'eliminado';
    Color estadoColor = activo ? Colors.green : (eliminado ? Colors.red : Colors.orange);
    Color estadoBg = activo ? Colors.green.shade50 : (eliminado ? Colors.red.shade50 : Colors.orange.shade50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: paciente.avatarColor,
          radius: 26,
          child: Text(
            paciente.iniciales,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(paciente.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text("DNI: ${paciente.dni}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: estadoBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "● ${paciente.estado[0].toUpperCase()}${paciente.estado.substring(1)}",
                style: TextStyle(
                  color: estadoColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetallePacienteView(paciente: paciente)),
        ),
      ),
    );
  }
}
