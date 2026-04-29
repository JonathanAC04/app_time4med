import 'package:flutter/material.dart';
import 'doctores_admin_view.dart';

class DetalleDoctorView extends StatelessWidget {
  final DoctorModel doctor;

  const DetalleDoctorView({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool activo = doctor.estado == 'activo';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // AppBar con el perfil
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF6B5DE8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B5DE8), Color(0xFF9B8BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      radius: 42,
                      child: CircleAvatar(
                        backgroundColor: doctor.avatarColor,
                        radius: 38,
                        child: Text(
                          doctor.iniciales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.especialidad,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido del detalle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de estado
                  _buildEstadoCard(activo),
                  const SizedBox(height: 20),

                  // Información personal
                  _buildSectionTitle("Información Personal"),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.email_outlined, "Correo Electrónico", doctor.email),
                    _buildDivider(),
                    _buildInfoRow(Icons.medical_services_outlined, "Especialidad", doctor.especialidad),
                    _buildDivider(),
                    _buildInfoRow(Icons.badge_outlined, "ID del Sistema", "#${doctor.id.padLeft(4, '0')}"),
                    _buildDivider(),
                    _buildInfoRow(
                      Icons.circle,
                      "Estado",
                      activo ? "Activo" : "Inactivo",
                      valueColor: activo ? Colors.green : Colors.orange,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Especialidades / áreas
                  _buildSectionTitle("Especialidades"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(doctor.especialidad, const Color(0xFF6B5DE8)),
                      _buildChip("Consulta General", Colors.teal),
                      _buildChip("Telemedicina", Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Historial de actividad
                  _buildSectionTitle("Historial de Actividad"),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.calendar_today_outlined, "Fecha de ingreso", "15 Enero 2023"),
                    _buildDivider(),
                    _buildInfoRow(Icons.people_outline, "Pacientes atendidos", "128"),
                    _buildDivider(),
                    _buildInfoRow(Icons.star_outline, "Calificación promedio", "4.8 / 5.0"),
                    _buildDivider(),
                    _buildInfoRow(Icons.access_time, "Última actividad", "Hace 2 horas"),
                  ]),
                  const SizedBox(height: 28),

                  // Botones de acción
                  _buildSectionTitle("Acciones"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          Icons.edit_outlined,
                          "Editar",
                          const Color(0xFF6B5DE8),
                          () => _showActionSnackBar(context, "Editar doctor (próximamente)"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          activo ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          activo ? "Desactivar" : "Activar",
                          activo ? Colors.orange : Colors.green,
                          () => _showActionSnackBar(
                            context,
                            activo ? "Doctor desactivado" : "Doctor activado",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        "Eliminar Doctor",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoCard(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: activo ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: activo ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            activo ? Icons.check_circle_outline : Icons.pause_circle_outline,
            color: activo ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Text(
            activo ? "Doctor Activo en el sistema" : "Doctor Inactivo en el sistema",
            style: TextStyle(
              color: activo ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B5DE8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 48);
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: onTap,
    );
  }

  void _showActionSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6B5DE8),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Eliminar Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "¿Estás seguro de que deseas eliminar a ${doctor.nombre}? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${doctor.nombre} eliminado del sistema"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
