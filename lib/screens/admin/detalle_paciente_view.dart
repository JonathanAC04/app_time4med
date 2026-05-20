import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class DetallePacienteView extends StatefulWidget {
  final String patientId;

  const DetallePacienteView({Key? key, required this.patientId}) : super(key: key);

  @override
  State<DetallePacienteView> createState() => _DetallePacienteViewState();
}

class _DetallePacienteViewState extends State<DetallePacienteView> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _showAssignDoctorDialog() async {
    final doctorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'doctor')
        .get();

    if (!mounted) return;
    if (doctorsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay doctores disponibles para asignar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedDoctorId;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Asignar doctor'),
          content: DropdownButtonFormField<String>(
            value: selectedDoctorId,
            hint: const Text('Selecciona un doctor'),
            isExpanded: true,
            items: doctorsSnapshot.docs.map((doc) {
              final data = doc.data();
              final nombre = (data['nombre'] as String?) ?? 'Doctor';
              final especialidad = (data['especialidad'] as String?) ?? 'Sin especialidad';
              return DropdownMenuItem(
                value: doc.id,
                child: Text('$nombre • $especialidad', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) => setDialogState(() => selectedDoctorId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _firestoreService.assignPatientToDoctor(patientId: widget.patientId);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paciente desasignado.'), backgroundColor: Colors.orange),
                );
              },
              child: const Text('Quitar asignación', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: selectedDoctorId == null
                  ? null
                  : () async {
                      final selectedDoctor = doctorsSnapshot.docs.firstWhere((doc) => doc.id == selectedDoctorId);
                      final doctorData = selectedDoctor.data();
                      await _firestoreService.assignPatientToDoctor(
                        patientId: widget.patientId,
                        doctorId: selectedDoctor.id,
                        doctorName: (doctorData['nombre'] as String?) ?? '',
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Paciente asignado correctamente.'),
                          backgroundColor: Color(0xFF6B5DE8),
                        ),
                      );
                    },
              child: const Text('Asignar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getUserStream(widget.patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final nombre = (data['nombre'] as String?) ?? 'Paciente';
          final edad = data['edad']?.toString() ?? 'N/D';
          final genero = (data['sexo'] as String?) ?? 'N/D';
          final email = (data['email'] as String?) ?? 'Sin correo';
          final fechaNacimiento = (data['fechaNacimiento'] as String?) ?? 'N/D';
          final doctorName = (data['medico'] as String?) ?? 'Sin doctor asignado';
          final hasDoctor = ((data['doctorId'] as String?) ?? '').trim().isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: const Color(0xFF6B5DE8),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
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
                          radius: 42,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                            _initials(nombre),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasDoctor ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: hasDoctor ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasDoctor ? Icons.check_circle_outline : Icons.info_outline,
                              color: hasDoctor ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasDoctor ? 'Asignado a $doctorName' : 'Paciente sin doctor asignado',
                                style: TextStyle(
                                  color: hasDoctor ? Colors.green.shade700 : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Información Personal'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(Icons.calendar_month_outlined, 'Fecha nacimiento', fechaNacimiento),
                        _buildDivider(),
                        _buildInfoRow(Icons.cake_outlined, 'Edad', '$edad años'),
                        _buildDivider(),
                        _buildInfoRow(Icons.wc_outlined, 'Género', genero),
                        _buildDivider(),
                        _buildInfoRow(Icons.email_outlined, 'Correo', email),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Médico responsable'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(Icons.local_hospital_outlined, 'Doctor asignado', doctorName),
                        _buildDivider(),
                        _buildInfoRow(Icons.badge_outlined, 'ID paciente', widget.patientId),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link, color: Colors.white),
                          label: const Text('Asignar doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5DE8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _showAssignDoctorDialog,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B5DE8)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 48);
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PA';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
