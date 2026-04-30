import 'package:flutter/material.dart';
import 'detalle_doctor_view.dart';

// Modelo simple de Doctor para la UI
class DoctorModel {
  final String id;
  final String nombre;
  final String especialidad;
  final String email;
  final String estado; // 'activo', 'inactivo'
  final String iniciales;
  final Color avatarColor;

  const DoctorModel({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.email,
    required this.estado,
    required this.iniciales,
    required this.avatarColor,
  });
}

// Datos de muestra
final List<DoctorModel> _doctoresMuestra = [
  const DoctorModel(id: '1', nombre: 'Dra. Ana Martínez', especialidad: 'Cardiología', email: 'ana.martinez@hospital.com', estado: 'activo', iniciales: 'AM', avatarColor: Color(0xFF6B5DE8)),
  const DoctorModel(id: '2', nombre: 'Dr. Carlos Rodríguez', especialidad: 'Neurología', email: 'carlos.rodriguez@hospital.com', estado: 'activo', iniciales: 'CR', avatarColor: Colors.teal),
  const DoctorModel(id: '3', nombre: 'Dra. Sofía Herrera', especialidad: 'Pediatría', email: 'sofia.herrera@hospital.com', estado: 'inactivo', iniciales: 'SH', avatarColor: Colors.orange),
  const DoctorModel(id: '4', nombre: 'Dr. Luis Pérez', especialidad: 'Medicina General', email: 'luis.perez@hospital.com', estado: 'activo', iniciales: 'LP', avatarColor: Colors.indigo),
  const DoctorModel(id: '5', nombre: 'Dra. María López', especialidad: 'Endocrinología', email: 'maria.lopez@hospital.com', estado: 'activo', iniciales: 'ML', avatarColor: Colors.pink),
];

class DoctoresAdminView extends StatefulWidget {
  const DoctoresAdminView({Key? key}) : super(key: key);

  @override
  _DoctoresAdminViewState createState() => _DoctoresAdminViewState();
}

class _DoctoresAdminViewState extends State<DoctoresAdminView> {
  final TextEditingController _searchController = TextEditingController();
  List<DoctorModel> _doctoresFiltrados = _doctoresMuestra;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarDoctores);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarDoctores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _doctoresFiltrados = _doctoresMuestra
          .where((d) =>
              d.nombre.toLowerCase().contains(query) ||
              d.especialidad.toLowerCase().contains(query))
          .toList();
    });
  }

  int get _totalActivos => _doctoresMuestra.where((d) => d.estado == 'activo').length;
  int get _totalInactivos => _doctoresMuestra.where((d) => d.estado == 'inactivo').length;

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
          "Gestión de Doctores",
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
                    _buildStatBadge("Total", _doctoresMuestra.length.toString(), Icons.medical_services_outlined, Colors.white),
                    const SizedBox(width: 10),
                    _buildStatBadge("Activos", _totalActivos.toString(), Icons.check_circle_outline, Colors.greenAccent),
                    const SizedBox(width: 10),
                    _buildStatBadge("Inactivos", _totalInactivos.toString(), Icons.pause_circle_outline, Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 16),
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Buscar doctor o especialidad...",
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
          // Lista de doctores
          Expanded(
            child: _doctoresFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      "No se encontraron doctores",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _doctoresFiltrados.length,
                    itemBuilder: (context, index) {
                      return _buildDoctorCard(_doctoresFiltrados[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Función: Nuevo Doctor (próximamente)"),
              backgroundColor: Color(0xFF6B5DE8),
            ),
          );
        },
        backgroundColor: const Color(0xFF6B5DE8),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text("Nuevo Doctor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    final bool activo = doctor.estado == 'activo';
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
          backgroundColor: doctor.avatarColor,
          radius: 26,
          child: Text(
            doctor.iniciales,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(doctor.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(doctor.especialidad, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: activo ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activo ? "● Activo" : "● Inactivo",
                style: TextStyle(
                  color: activo ? Colors.green.shade700 : Colors.orange.shade700,
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
          MaterialPageRoute(builder: (_) => DetalleDoctorView(doctor: doctor)),
        ),
      ),
    );
  }
}
