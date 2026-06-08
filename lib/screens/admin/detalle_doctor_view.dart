import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class DetalleDoctorView extends StatefulWidget {
  final String doctorId;

  const DetalleDoctorView({Key? key, required this.doctorId}) : super(key: key);

  @override
  State<DetalleDoctorView> createState() => _DetalleDoctorViewState();
}

class _DetalleDoctorViewState extends State<DetalleDoctorView> {
  final FirestoreService _service = FirestoreService();

  void _snack(String msg, {Color color = const Color(0xFF6B5DE8)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _editarDoctor(Map<String, dynamic> data) async {
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final espCtrl = TextEditingController(text: data['especialidad'] ?? '');
    final telCtrl = TextEditingController(text: data['telefono'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar doctor'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: espCtrl,
                    decoration: const InputDecoration(labelText: 'Especialidad'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.doctorId)
                            .update({
                          'nombre': nombreCtrl.text.trim(),
                          'especialidad': espCtrl.text.trim(),
                          'telefono': telCtrl.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _snack('Doctor actualizado correctamente.');
                      } catch (e) {
                        setDialogState(() => loading = false);
                        _snack('Error al actualizar: $e', color: Colors.red);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarDoctor(String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar doctor'),
        content: Text(
            '¿Seguro que deseas eliminar a "$nombre"? Sus pacientes quedarán '
            'sin doctor asignado. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final pacientes = await FirebaseFirestore.instance
          .collection('users')
          .where('doctorId', isEqualTo: widget.doctorId)
          .get();
      for (final p in pacientes.docs) {
        await p.reference.update({'doctorId': '', 'medico': ''});
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctorId)
          .delete();
      if (!mounted) return;
      _snack('Doctor eliminado.', color: Colors.orange);
      Navigator.pop(context);
    } catch (e) {
      _snack('Error al eliminar: $e', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.getUserStream(widget.doctorId),
        builder: (context, doctorSnap) {
          if (doctorSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
          }
          final doctorData = doctorSnap.data?.data() ?? <String, dynamic>{};
          final nombre = (doctorData['nombre'] as String?) ?? 'Doctor';
          final especialidad =
              (doctorData['especialidad'] as String?) ?? 'Sin especialidad';
          final email = (doctorData['email'] as String?) ?? 'Sin correo';
          final telefono =
              (doctorData['telefono'] as String?) ?? 'No registrado';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('rol', isEqualTo: 'paciente')
                .where('doctorId', isEqualTo: widget.doctorId)
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
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        tooltip: 'Editar',
                        onPressed: () => _editarDoctor(doctorData),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.white),
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminarDoctor(nombre),
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
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
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
                            _buildInfoRow(Icons.local_phone_outlined, 'Teléfono',
                                telefono),
                            _buildDivider(),
                            _buildInfoRow(Icons.medical_services_outlined,
                                'Especialidad', especialidad),
                            _buildDivider(),
                            _buildInfoRow(Icons.badge_outlined, 'ID de usuario',
                                widget.doctorId),
                          ]),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Resumen clínico'),
                          const SizedBox(height: 12),
                          _buildInfoCard([
                            _buildInfoRow(Icons.people_alt_outlined,
                                'Pacientes asignados', patientsCount.toString()),
                            _buildDivider(),
                            _buildInfoRow(
                                Icons.verified_user_outlined, 'Rol', 'Doctor'),
                          ]),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6B5DE8),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar'),
                                  onPressed: () => _editarDoctor(doctorData),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Eliminar'),
                                  onPressed: () => _eliminarDoctor(nombre),
                                ),
                              ),
                            ],
                          ),
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
    return Text(title,
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
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
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}