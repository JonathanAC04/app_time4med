import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class PacienteDoctorDetail extends StatefulWidget {
  final String doctorId;
  final String patientId;

  const PacienteDoctorDetail({
    Key? key,
    required this.doctorId,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PacienteDoctorDetail> createState() => _PacienteDoctorDetailState();
}

class _PacienteDoctorDetailState extends State<PacienteDoctorDetail> {
  final FirestoreService _firestoreService = FirestoreService();

  static const List<String> _dosisOpciones = [
    '1 tableta (10mg)',
    '1 tableta (20mg)',
    '1 tableta (50mg)',
    '1 tableta (100mg)',
    '1 cápsula (250mg)',
    '1 cápsula (500mg)',
    '5ml jarabe',
    '10ml jarabe',
    '1 inyección',
    'Otro',
  ];

  Future<void> _showMedicationForm({
    String? medicamentoId,
    String? nombreActual,
    String? dosisActual,
    DateTime? fechaHoraActual,
  }) async {
    final nombreController = TextEditingController(text: nombreActual ?? '');
    String? dosis = dosisActual;
    DateTime? fechaHora = fechaHoraActual;
    bool loading = false;
    final isEditing = medicamentoId != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar receta' : 'Nueva receta',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre del medicamento",
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dosis,
                    decoration: const InputDecoration(
                      labelText: 'Dosis',
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    items: _dosisOpciones
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setModalState(() => dosis = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: fechaHora ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 2)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay.fromDateTime(fechaHora ?? DateTime.now()),
                      );
                      if (time == null) return;
                      setModalState(
                        () => fechaHora = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha y hora',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        fechaHora == null
                            ? 'Seleccionar fecha y hora'
                            : '${fechaHora!.day.toString().padLeft(2, '0')}/${fechaHora!.month.toString().padLeft(2, '0')}/${fechaHora!.year} ${fechaHora!.hour.toString().padLeft(2, '0')}:${fechaHora!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final nombre = nombreController.text.trim();
                              if (nombre.isEmpty ||
                                  dosis == null ||
                                  fechaHora == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Completa nombre, dosis y fecha/hora.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setModalState(() => loading = true);
                              try {
                                if (isEditing) {
                                  await _firestoreService.updateMedicamento(
                                    widget.patientId,
                                    medicamentoId!,
                                    {
                                      'nombre': nombre,
                                      'dosis': dosis,
                                      'fecha': '${fechaHora!.year.toString().padLeft(4, '0')}-${fechaHora!.month.toString().padLeft(2, '0')}-${fechaHora!.day.toString().padLeft(2, '0')}',
                                      'hora':
                                          '${fechaHora!.hour.toString().padLeft(2, '0')}:${fechaHora!.minute.toString().padLeft(2, '0')}',
                                      'fechaHora': Timestamp.fromDate(fechaHora!),
                                    },
                                  );
                                  await _firestoreService.addNotificationToUser(
                                    uid: widget.patientId,
                                    title: 'Receta actualizada',
                                    body: 'Tu médico actualizó "$nombre".',
                                    type: 'DOCTOR_MEDICATION_UPDATED',
                                  );
                                } else {
                                  await _firestoreService.addMedicamento(
                                    widget.patientId,
                                    nombre,
                                    dosis!,
                                    fechaHora!,
                                  );
                                  await _firestoreService.addNotificationToUser(
                                    uid: widget.patientId,
                                    title: 'Nueva receta médica',
                                    body:
                                        'Tu médico te recetó "$nombre" ($dosis).',
                                    type: 'DOCTOR_MEDICATION_ASSIGNED',
                                  );
                                }
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing
                                        ? '✅ Receta actualizada.'
                                        : '✅ Receta asignada al paciente.'),
                                    backgroundColor: const Color(0xFF6B5DE8),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => loading = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar receta: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5DE8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isEditing
                                  ? 'Guardar cambios'
                                  : 'Asignar medicamento',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteMedication({
    required String docId,
    required String medicationName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Deseas eliminar "$medicationName" de la receta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _firestoreService.deleteMedicamento(widget.patientId, docId);
      await _firestoreService.addNotificationToUser(
        uid: widget.patientId,
        title: 'Receta actualizada',
        body: 'Tu médico eliminó "$medicationName".',
        type: 'DOCTOR_MEDICATION_DELETED',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Medicamento eliminado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime? _extractFechaHora(Map<String, dynamic> data) {
    final ts = data['fechaHora'];
    if (ts is Timestamp) return ts.toDate();
    final fecha = data['fecha'] as String?;
    final hora = data['hora'] as String?;
    if (fecha == null || hora == null || !fecha.contains('-')) return null;
    final d = fecha.split('-');
    final h = hora.split(':');
    if (d.length != 3 || h.length < 2) return null;
    final y = int.tryParse(d[0]);
    final m = int.tryParse(d[1]);
    final day = int.tryParse(d[2]);
    final hh = int.tryParse(h[0]);
    final mm = int.tryParse(h[1]);
    if ([y, m, day, hh, mm].contains(null)) return null;
    return DateTime(y!, m!, day!, hh!, mm!);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getUserStream(widget.patientId),
      builder: (context, patientSnap) {
        if (patientSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5DE8)),
            ),
          );
        }
        final patient = patientSnap.data?.data() ?? <String, dynamic>{};
        final nombre = (patient['nombre'] as String?) ?? 'Paciente';
        final apellidos = (patient['apellidos'] as String?) ?? '';

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Perfil del paciente'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Asignar receta',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showMedicationForm(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF6B5DE8),
            onPressed: () => _showMedicationForm(),
            icon: const Icon(Icons.medication, color: Colors.white),
            label: const Text('Recetar', style: TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE8E5FF),
                        child: Icon(Icons.person, color: Color(0xFF6B5DE8)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$nombre $apellidos'.trim(),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sexo: ${(patient['sexo'] as String?) ?? 'N/D'} • Peso: ${patient['peso']?.toString() ?? 'N/D'} kg • Altura: ${patient['estatura']?.toString() ?? 'N/D'} m',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle('Historial de medicamentos'),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestoreService.getMedicamentosStream(widget.patientId),
                  builder: (context, medSnap) {
                    if (medSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: Color(0xFF6B5DE8)),
                        ),
                      );
                    }
                    final meds = medSnap.data?.docs ?? [];
                    if (meds.isEmpty) {
                      return const _EmptyCard(
                          message: 'Este paciente no tiene recetas todavía.');
                    }

                    int tomadas = 0;
                    int noTomadas = 0;
                    int pospuestas = 0;
                    for (final med in meds) {
                      final status = (med.data()['status'] as String?) ?? '';
                      if (status == 'TOMADO') tomadas++;
                      if (status == 'NO_TOMADO') noTomadas++;
                      if (status == 'POSPUESTO') pospuestas++;
                    }

                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tomadas: $tomadas'),
                              Text('No tomadas: $noTomadas'),
                              Text('Pospuestas: $pospuestas'),
                            ],
                          ),
                        ),
                        ...meds.map((doc) {
                          final data = doc.data();
                          final nombreMed =
                              (data['nombre'] as String?) ?? 'Medicamento';
                          final dosis = (data['dosis'] as String?) ?? 'N/D';
                          final fecha = (data['fecha'] as String?) ?? 'N/D';
                          final hora = (data['hora'] as String?) ?? 'N/D';
                          final status = (data['status'] as String?) ?? 'PENDIENTE';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nombreMed,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('$dosis • $fecha $hora',
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12)),
                                      Text('Estado: $status',
                                          style: const TextStyle(
                                              color: Color(0xFF6B5DE8),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showMedicationForm(
                                    medicamentoId: doc.id,
                                    nombreActual: nombreMed,
                                    dosisActual: dosis,
                                    fechaHoraActual: _extractFechaHora(data),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteMedication(
                                    docId: doc.id,
                                    medicationName: nombreMed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _sectionTitle('Próximas citas'),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestoreService.getCitasStream(widget.patientId),
                  builder: (context, citasSnap) {
                    if (citasSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    final citas = citasSnap.data?.docs ?? [];
                    if (citas.isEmpty) {
                      return const _EmptyCard(
                          message: 'No hay citas próximas registradas.');
                    }
                    return Column(
                      children: citas.map((doc) {
                        final data = doc.data();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pink.shade100),
                          ),
                          child: Text(
                            '${(data['fecha'] as String?) ?? 'N/D'} ${(data['hora'] as String?) ?? ''} • ${(data['motivo'] as String?) ?? 'Sin motivo'}',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}
