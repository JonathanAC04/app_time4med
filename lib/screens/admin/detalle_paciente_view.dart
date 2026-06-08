import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class DetallePacienteView extends StatefulWidget {
  final String patientId;

  const DetallePacienteView({Key? key, required this.patientId})
      : super(key: key);

  @override
  State<DetallePacienteView> createState() => _DetallePacienteViewState();
}

class _DetallePacienteViewState extends State<DetallePacienteView> {
  final FirestoreService _firestoreService = FirestoreService();

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

  Future<void> _editarPaciente(Map<String, dynamic> data) async {
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final edadCtrl =
        TextEditingController(text: data['edad']?.toString() ?? '');
    String sexo = (data['sexo'] as String?) ?? 'Masculino';
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar paciente'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: ['Masculino', 'Femenino', 'Otro'].contains(sexo)
                        ? sexo
                        : 'Masculino',
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Masculino', child: Text('Masculino')),
                      DropdownMenuItem(
                          value: 'Femenino', child: Text('Femenino')),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => sexo = v ?? 'Masculino'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: edadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad'),
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
                            .doc(widget.patientId)
                            .update({
                          'nombre': nombreCtrl.text.trim(),
                          'sexo': sexo,
                          'edad': int.tryParse(edadCtrl.text.trim()),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _snack('Paciente actualizado correctamente.');
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

  Future<void> _eliminarPaciente(String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar paciente'),
        content: Text(
            '¿Seguro que deseas eliminar a "$nombre"? Se borrará su perfil. '
            'Esta acción no se puede deshacer.'),
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .delete();
      if (!mounted) return;
      _snack('Paciente eliminado.', color: Colors.orange);
      Navigator.pop(context);
    } catch (e) {
      _snack('Error al eliminar: $e', color: Colors.red);
    }
  }

  Future<void> _showAssignDoctorDialog() async {
    final doctorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'doctor')
        .get();

    if (!mounted) return;
    if (doctorsSnapshot.docs.isEmpty) {
      _snack('No hay doctores disponibles para asignar.',
          color: Colors.orange);
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
              final especialidad =
                  (data['especialidad'] as String?) ?? 'Sin especialidad';
              return DropdownMenuItem(
                value: doc.id,
                child: Text('$nombre • $especialidad',
                    overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) =>
                setDialogState(() => selectedDoctorId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _firestoreService.assignPatientToDoctor(
                    patientId: widget.patientId);
                if (!mounted) return;
                Navigator.pop(ctx);
                _snack('Paciente desasignado.', color: Colors.orange);
              },
              child: const Text('Quitar asignación',
                  style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: selectedDoctorId == null
                  ? null
                  : () async {
                      final selectedDoctor = doctorsSnapshot.docs
                          .firstWhere((doc) => doc.id == selectedDoctorId);
                      final doctorData = selectedDoctor.data();
                      await _firestoreService.assignPatientToDoctor(
                        patientId: widget.patientId,
                        doctorId: selectedDoctor.id,
                        doctorName: (doctorData['nombre'] as String?) ?? '',
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _snack('Paciente asignado correctamente.');
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
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final nombre = (data['nombre'] as String?) ?? 'Paciente';
          final edad = data['edad']?.toString() ?? 'N/D';
          final genero = (data['sexo'] as String?) ?? 'N/D';
          final email = (data['email'] as String?) ?? 'Sin correo';
          final fechaNacimiento =
              (data['fechaNacimiento'] as String?) ?? 'N/D';
          final doctorName =
              (data['medico'] as String?) ?? 'Sin doctor asignado';
          final hasDoctor =
              ((data['doctorId'] as String?) ?? '').trim().isNotEmpty;

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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: 'Editar',
                    onPressed: () => _editarPaciente(data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'Eliminar',
                    onPressed: () => _eliminarPaciente(nombre),
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
                          radius: 42,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                            _initials(nombre),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasDoctor
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: hasDoctor
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasDoctor
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              color: hasDoctor ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasDoctor
                                    ? 'Asignado a $doctorName'
                                    : 'Paciente sin doctor asignado',
                                style: TextStyle(
                                  color: hasDoctor
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
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
                        _buildInfoRow(Icons.calendar_month_outlined,
                            'Fecha nacimiento', fechaNacimiento),
                        _buildDivider(),
                        _buildInfoRow(
                            Icons.cake_outlined, 'Edad', '$edad años'),
                        _buildDivider(),
                        _buildInfoRow(Icons.wc_outlined, 'Género', genero),
                        _buildDivider(),
                        _buildInfoRow(Icons.email_outlined, 'Correo', email),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Médico responsable'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(Icons.local_hospital_outlined,
                            'Doctor asignado', doctorName),
                        _buildDivider(),
                        _buildInfoRow(Icons.badge_outlined, 'ID paciente',
                            widget.patientId),
                      ]),
                      const SizedBox(height: 20),
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
                              icon: const Icon(Icons.link),
                              label: const Text('Asignar'),
                              onPressed: _showAssignDoctorDialog,
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
                              onPressed: () => _eliminarPaciente(nombre),
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
    if (parts.isEmpty) return 'PA';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}