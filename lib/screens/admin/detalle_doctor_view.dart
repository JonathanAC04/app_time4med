import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class DetalleDoctorView extends StatelessWidget {
  final String doctorId;

  const DetalleDoctorView({Key? key, required this.doctorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.getUserStream(doctorId),
        builder: (context, doctorSnap) {
          if (doctorSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
          }
          final doctorData = doctorSnap.data?.data() ?? <String, dynamic>{};
          final nombre = (doctorData['nombre'] as String?) ?? 'Doctor';
          final especialidad = (doctorData['especialidad'] as String?) ?? 'Sin especialidad';
          final email = (doctorData['email'] as String?) ?? 'Sin correo';
          final telefono = (doctorData['telefono'] as String?) ?? 'No registrado';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('rol', isEqualTo: 'paciente')
                .where('doctorId', isEqualTo: doctorId)
                .snapshots(),
            builder: (context, patientsSnap) {
              final patientsCount = patientsSnap.data?.size ?? 0;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
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
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              child: Text(
                                _initials(nombre),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              especialidad,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Información del doctor'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            _buildInfoRow(Icons.email_outlined, 'Correo', email),
                            _buildDivider(),
                            _buildInfoRow(Icons.local_phone_outlined, 'Teléfono', telefono),
                            _buildDivider(),
                            _buildInfoRow(Icons.medical_services_outlined, 'Especialidad', especialidad),
                            _buildDivider(),
                            _buildInfoRow(Icons.badge_outlined, 'ID de usuario', doctorId),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Resumen clínico'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            _buildInfoRow(Icons.people_alt_outlined, 'Pacientes asignados', patientsCount.toString()),
                            _buildDivider(),
                            _buildInfoRow(Icons.verified_user_outlined, 'Rol', 'Doctor'),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
