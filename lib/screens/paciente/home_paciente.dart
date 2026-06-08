import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/firestore_service.dart';
import '../../services/local_notification_service.dart';
import '../../utils/date_helpers.dart';
import 'perfil_paciente.dart';
import 'agenda_paciente.dart';
import 'salud_paciente.dart';
import 'notificaciones_paciente.dart';
import '../../data/catalogos.dart';

class HomePaciente extends StatefulWidget {
  const HomePaciente({Key? key}) : super(key: key);

  @override
  _HomePacienteState createState() => _HomePacienteState();
}

class _HomePacienteState extends State<HomePaciente> {
  int _selectedIndex = 0;
  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _pantallas = [
      _MiDiaView(
        onGoToProfile: () => setState(() => _selectedIndex = 3),
      ),
      AgendaPaciente(
        onGoToProfile: () => setState(() => _selectedIndex = 3),
      ),
      const SaludPaciente(),
      const PerfilPaciente(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // IndexedStack mantiene vivas las pantallas para que no se recarguen al cambiar de pestaña
      body: IndexedStack(
        index: _selectedIndex,
        children: _pantallas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF6B5DE8),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Mi Día"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Agenda"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Salud"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
        ],
      ),
    );
  }
}

// --- VISTA "MI DÍA" ---
class _MiDiaView extends StatefulWidget {
  final VoidCallback onGoToProfile;

  const _MiDiaView({required this.onGoToProfile, Key? key}) : super(key: key);

  @override
  _MiDiaViewState createState() => _MiDiaViewState();
}

class _MiDiaViewState extends State<_MiDiaView> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Timer? _exactReminderTimer;
  final Set<String> _shownExactReminderKeys = <String>{};
  bool _isReminderModalOpen = false;
  List<QueryDocumentSnapshot> _todayDocsCache = <QueryDocumentSnapshot>[];

  static const List<String> _dosisOpciones = [
    '1 tableta (10mg)',
    '1 tableta (20mg)',
    '1 tableta (50mg)',
    '1 tableta (100mg)',
    '1 cápsula (250mg)',
    '1 cápsula (500mg)',
    '1 comprimido (10mg)',
    '1 comprimido (850mg)',
    '5ml jarabe',
    '10ml jarabe',
    '1 inyección',
    'Otro',
  ];

  String _todayStr() => formatDateToString(DateTime.now());

  @override
  void initState() {
    super.initState();
    _sincronizarNotificaciones();
    _exactReminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _maybeShowExactTimeReminder();
    });
  }

  @override
  void dispose() {
    _exactReminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _sincronizarNotificaciones() async {
    if (_uid == null) return;
    try {
      final medsSnap = await _firestoreService.getMedicamentosOnce(_uid!);
      for (final doc in medsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final fechaHora = _extractFechaHora(data);
        if (fechaHora == null) continue;
        await LocalNotificationService.instance.scheduleMedicamentoReminders(
          uid: _uid!,
          medicamentoId: doc.id,
          nombre: (data['nombre'] as String?) ?? 'Medicamento',
          dosis: (data['dosis'] as String?) ?? '',
          fechaHora: fechaHora,
        );
      }

      final citasSnap = await _firestoreService.getCitasOnce(_uid!);
      for (final doc in citasSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final fechaHora = _extractFechaHora(data);
        if (fechaHora == null) continue;
        await LocalNotificationService.instance.scheduleCitaReminders(
          uid: _uid!,
          citaId: doc.id,
          motivo: (data['motivo'] as String?) ?? 'Cita médica',
          fechaHora: fechaHora,
        );
      }
    } catch (e) {
      debugPrint('Error al sincronizar notificaciones: $e');
    }
  }

  DateTime? _extractFechaHora(Map<String, dynamic> data) {
    final timestamp = data['fechaHora'];
    if (timestamp is Timestamp) return timestamp.toDate();
    final fecha = parseDate(data['fecha'] as String?);
    final hora = (data['hora'] as String?) ?? '';
    final parts = hora.split(':');
    if (fecha == null || parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, h, m);
  }

  void _abrirMenuAgregar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Qué deseas agregar?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_outlined,
                    color: Color(0xFF6B5DE8), size: 28),
              ),
              title: const Text("Agregar próxima toma",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text("Registra un medicamento programado",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _abrirModalAgregarMedicamento();
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month,
                    color: Color(0xFFFF4C79), size: 28),
              ),
              title: const Text("Agregar próxima cita médica",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text("Agenda una visita con el doctor",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _abrirModalAgregarCita();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalAgregarCita() {
    final motivoController = TextEditingController();
    DateTime? selectedFecha;
    TimeOfDay? selectedHora;
    bool isLoading = false;

    showModalBottomSheet(
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Nueva Cita Médica",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Fecha
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFFFF4C79)),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) {
                        setModalState(() => selectedFecha = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Fecha de la cita",
                        prefixIcon: Icon(Icons.calendar_month, color: Color(0xFFFF4C79)),
                      ),
                      child: Text(
                        selectedFecha != null
                            ? "${selectedFecha!.day.toString().padLeft(2, '0')}/${selectedFecha!.month.toString().padLeft(2, '0')}/${selectedFecha!.year}"
                            : "Seleccionar fecha",
                        style: TextStyle(
                          color: selectedFecha != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Hora
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFFFF4C79)),
                          ),
                          child: child!,
                        ),
                      );
                      if (time != null) {
                        setModalState(() => selectedHora = time);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Hora de la cita",
                        prefixIcon: Icon(Icons.access_time, color: Color(0xFFFF4C79)),
                      ),
                      child: Text(
                        selectedHora != null
                            ? "${selectedHora!.hour.toString().padLeft(2, '0')}:${selectedHora!.minute.toString().padLeft(2, '0')}"
                            : "Seleccionar hora",
                        style: TextStyle(
                          color: selectedHora != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Motivo
                  TextField(
                    controller: motivoController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Motivo de la cita",
                      prefixIcon: Icon(Icons.notes_outlined, color: Color(0xFFFF4C79)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4C79),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final motivo = motivoController.text.trim();
                              if (selectedFecha == null ||
                                  selectedHora == null ||
                                  motivo.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Por favor completa todos los campos"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isLoading = true);

                              try {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) throw Exception("Usuario no autenticado");

                                final citaId = await _firestoreService.addCita(
                                    uid, selectedFecha!, selectedHora!, motivo);
                                final citaFechaHora = DateTime(
                                  selectedFecha!.year,
                                  selectedFecha!.month,
                                  selectedFecha!.day,
                                  selectedHora!.hour,
                                  selectedHora!.minute,
                                );
                                await LocalNotificationService.instance
                                    .scheduleCitaReminders(
                                  uid: uid,
                                  citaId: citaId,
                                  motivo: motivo,
                                  fechaHora: citaFechaHora,
                                );

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("✅ Cita guardada exitosamente"),
                                      backgroundColor: Color(0xFFFF4C79),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("❌ Error al guardar: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Guardar Cita",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _abrirModalAgregarMedicamento() {
    final nombreController = TextEditingController();
    String? selectedDosis;
    DateTime? selectedFechaHora;
    bool isLoading = false;

    showModalBottomSheet(
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Nuevo Medicamento",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nombre
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: nombreController.text),
                    optionsBuilder: (TextEditingValue val) {
                      if (val.text.isEmpty) return const Iterable<String>.empty();
                      final q = val.text.toLowerCase();
                      return Catalogos.medicamentos
                          .where((m) => m.toLowerCase().contains(q))
                          .take(8);
                    },
                    onSelected: (sel) => nombreController.text = sel,
                    fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
                      // Sincronizamos el controller interno del Autocomplete con el externo
                      ctrl.text = nombreController.text;
                      return TextField(
                        controller: ctrl,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: "Nombre del medicamento",
                          prefixIcon: Icon(Icons.medication_outlined),
                        ),
                        onChanged: (v) => nombreController.text = v,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Dosis (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedDosis,
                    decoration: const InputDecoration(
                      labelText: "Dosis",
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                    items: _dosisOpciones
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedDosis = v),
                  ),
                  const SizedBox(height: 12),
                  // Fecha y Hora (DatePicker + TimePicker)
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFF6B5DE8)),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF6B5DE8)),
                            ),
                            child: child!,
                          ),
                        );
                        if (time != null) {
                          setModalState(() {
                            selectedFechaHora = DateTime(
                              date.year, date.month, date.day,
                              time.hour, time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Fecha y Hora",
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedFechaHora != null
                            ? "${selectedFechaHora!.day.toString().padLeft(2, '0')}/${selectedFechaHora!.month.toString().padLeft(2, '0')}/${selectedFechaHora!.year}  ${selectedFechaHora!.hour.toString().padLeft(2, '0')}:${selectedFechaHora!.minute.toString().padLeft(2, '0')}"
                            : "Seleccionar fecha y hora",
                        style: TextStyle(
                          color: selectedFechaHora != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5DE8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final nombre = nombreController.text.trim();
                              if (nombre.isEmpty ||
                                  selectedDosis == null ||
                                  selectedFechaHora == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Por favor completa todos los campos"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isLoading = true);

                              try {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) throw Exception("Usuario no autenticado");

                                final medicamentoId = await _firestoreService.addMedicamento(
                                    uid, nombre, selectedDosis!, selectedFechaHora!);

                                // La notificación es secundaria: si falla, no rompemos el flujo.
                                try {
                                  await LocalNotificationService.instance.scheduleMedicamentoReminders(
                                    uid: uid,
                                    medicamentoId: medicamentoId,
                                    nombre: nombre,
                                    dosis: selectedDosis!,
                                    fechaHora: selectedFechaHora!,
                                  );
                                } catch (notifError) {
                                  debugPrint('No se pudo programar el recordatorio local: $notifError');
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("✅ Medicamento guardado exitosamente"),
                                      backgroundColor: Color(0xFF6B5DE8),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("❌ Error al guardar: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Guardar Medicamento",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _maybeShowExactTimeReminder() {
    if (_isReminderModalOpen || _todayDocsCache.isEmpty) return;
    final now = DateTime.now();
    final nowMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    for (final doc in _todayDocsCache) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? 'PENDIENTE';
      if (status == 'TOMADO' || status == 'NO_TOMADO') continue;

      final fechaHora = _extractFechaHora(data);
      if (fechaHora == null) continue;
      final medMinute =
          DateTime(fechaHora.year, fechaHora.month, fechaHora.day, fechaHora.hour, fechaHora.minute);
      final key = '${doc.id}-${medMinute.millisecondsSinceEpoch}';

      if (medMinute == nowMinute && !_shownExactReminderKeys.contains(key)) {
        _shownExactReminderKeys.add(key);
        _abrirModalRecordatorioMedicamento(
          docId: doc.id,
          nombre: (data['nombre'] as String?) ?? '',
          dosis: (data['dosis'] as String?) ?? '',
          fechaHora: fechaHora,
        );
        break;
      }
    }
  }

  Future<void> _abrirModalRecordatorioMedicamento({
    required String docId,
    required String nombre,
    required String dosis,
    required DateTime fechaHora,
  }) async {
    if (!mounted) return;
    _isReminderModalOpen = true;
    try {
      await showModalBottomSheet(
        context: context,
        isDismissible: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior (handle)
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Ícono grande con degradado
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B5DE8), Color(0xFF9B8BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B5DE8).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.medication_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                "Es hora de tu medicamento",
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              // Chips de dosis y hora
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _infoChip(Icons.scale_outlined, dosis),
                  const SizedBox(width: 10),
                  _infoChip(Icons.access_time_rounded,
                      formatTimeToString(fechaHora)),
                ],
              ),
              const SizedBox(height: 28),
              // Botón principal "Ya la tomé"
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5DE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: const Text("Ya la tomé",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _actualizarMedicamentoStatus(docId, 'TOMADO',
                        medicationName: nombre);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Botones secundarios
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade200),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.snooze_rounded, size: 20),
                        label: const Text("Posponer",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _abrirModalPosponerToma(
                            docId: docId,
                            nombre: nombre,
                            dosis: dosis,
                            fechaHoraBase: fechaHora,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.red.shade100),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text("No la tomé",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _actualizarMedicamentoStatus(docId, 'NO_TOMADO',
                              medicationName: nombre);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } finally {
      _isReminderModalOpen = false;
    }
  }

  // Chip reutilizable para mostrar dosis y hora en el recordatorio.
  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B5DE8)),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF6B5DE8),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  void _abrirModalPosponerToma({
    required String docId,
    required String nombre,
    required String dosis,
    required DateTime fechaHoraBase,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Posponer toma",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Selecciona cuándo quieres recibir el próximo recordatorio."),
            const SizedBox(height: 16),
            _buildPosponerOption(ctx, "15 minutos", () {
              _posponerMedicamento(docId, nombre, dosis, fechaHoraBase.add(const Duration(minutes: 15)));
            }),
            _buildPosponerOption(ctx, "30 minutos", () {
              _posponerMedicamento(docId, nombre, dosis, fechaHoraBase.add(const Duration(minutes: 30)));
            }),
            _buildPosponerOption(ctx, "1 hora", () {
              _posponerMedicamento(docId, nombre, dosis, fechaHoraBase.add(const Duration(hours: 1)));
            }),
            _buildPosponerOption(ctx, "Elegir hora personalizada", () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(fechaHoraBase.add(const Duration(minutes: 15))),
              );
              if (time == null) return;
              final now = DateTime.now();
              final selected = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              final scheduled = selected.isAfter(now)
                  ? selected
                  : selected.add(const Duration(days: 1));
              _posponerMedicamento(docId, nombre, dosis, scheduled);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPosponerOption(
      BuildContext ctx, String title, VoidCallback onPressed) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(ctx);
        onPressed();
      },
    );
  }

  Future<void> _posponerMedicamento(
      String docId, String nombre, String dosis, DateTime nuevaFechaHora) async {
    if (_uid == null) return;
    try {
      // 1) Lo importante: guardar en Firestore.
      await _firestoreService.updateMedicamento(_uid!, docId, {
        'fecha': formatDateToString(nuevaFechaHora),
        'hora': formatTimeToString(nuevaFechaHora),
        'fechaHora': Timestamp.fromDate(nuevaFechaHora),
        'status': 'POSPUESTO',
      });

      // 2) Secundario: reprogramar la notificación local. Si falla, no rompe.
      try {
        await LocalNotificationService.instance.scheduleMedicamentoReminders(
          uid: _uid!,
          medicamentoId: docId,
          nombre: nombre,
          dosis: dosis,
          fechaHora: nuevaFechaHora,
        );
      } catch (notifError) {
        debugPrint('No se pudo reprogramar el recordatorio: $notifError');
      }

      // 3) Secundario: avisar al doctor. Si falla, no rompe.
      try {
        await _firestoreService.notifyDoctorMedicationStatus(
          patientId: _uid!,
          medicationName: nombre,
          status: 'POSPUESTO',
        );
      } catch (notifyError) {
        debugPrint('No se pudo notificar al doctor: $notifyError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Medicamento pospuesto correctamente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al posponer: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _actualizarMedicamentoStatus(
    String docId,
    String nuevoStatus, {
    required String medicationName,
  }) async {
    if (_uid == null) return;
    try {
      // Lo importante: guardar el estado en Firestore.
      await _firestoreService.updateMedicamentoStatus(_uid!, docId, nuevoStatus);

      // Secundario: avisar al doctor. Si falla, no rompe el flujo.
      if (nuevoStatus == 'NO_TOMADO') {
        try {
          await _firestoreService.notifyDoctorMedicationStatus(
            patientId: _uid!,
            medicationName: medicationName,
            status: nuevoStatus,
          );
        } catch (notifyError) {
          debugPrint('No se pudo notificar al doctor: $notifyError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoStatus == 'TOMADO'
                  ? "✅ Toma registrada."
                  : "⚠️ Estado actualizado: $nuevoStatus",
            ),
            backgroundColor:
                nuevoStatus == 'TOMADO' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar estado: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayLabel =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _uid == null
            ? null
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestoreService.getUserNotificationsStream(_uid!),
                builder: (context, snap) {
                  final noLeidas = (snap.data?.docs ?? [])
                      .where((d) => (d.data()['read'] as bool?) != true)
                      .length;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        tooltip: "Notificaciones",
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificacionesPaciente()),
                          );
                        },
                      ),
                      if (noLeidas > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              noLeidas > 9 ? '9+' : '$noLeidas',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        title: Column(children: [
          const Text("HOY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(todayLabel, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Perfil",
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.person, color: Colors.black54),
            ),
            onPressed: widget.onGoToProfile,
          ),
        ],
      ),
      body: _uid == null
          ? const Center(
              child: Text("Inicia sesión para ver tus medicamentos.",
                  style: TextStyle(color: Colors.grey)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.getMedicamentosStream(_uid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
                }

                final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                // Filtrar meds de hoy (solo los que tienen fecha asignada para hoy)
                final today = _todayStr();
                 final todayDocs = docs.where((doc) {
                   final data = doc.data();
                  final fecha = data['fecha'] as String?;
                  if (fecha == null) return false; // Medications without a date are not shown as today's
                  return fecha == today;
                }).toList();
                _todayDocsCache = todayDocs.cast<QueryDocumentSnapshot>();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _maybeShowExactTimeReminder();
                });

                // Calcular progreso
                final total = todayDocs.length;
                 final tomados = todayDocs.where((doc) {
                   final data = doc.data();
                  return (data['status'] as String?) == 'TOMADO';
                }).length;
                final progress = total > 0 ? tomados / total : 0.0;
                final progressPct = (progress * 100).round();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de progreso dinámica
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Progreso de hoy",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Text("$progressPct%",
                                      style: const TextStyle(
                                          color: Color(0xFF6B5DE8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("$tomados de $total dosis",
                                style: const TextStyle(
                                    color: Color(0xFF6B5DE8),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white,
                                color: const Color(0xFF6B5DE8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text("Próximas Tomas",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      if (todayDocs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              "No tienes medicamentos para hoy.\nPresiona + para agregar uno.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        )
                      else
                        ...todayDocs.map((doc) {
                          final data = doc.data();
                          final status =
                              (data['status'] as String?) ?? 'PENDIENTE';
                          return _buildMedicationCard(
                            data['hora'] ?? '',
                            data['nombre'] ?? '',
                            data['dosis'] ?? '',
                            doc.id,
                            status,
                            _extractFechaHora(data),
                          );
                        }).toList(),
                      const SizedBox(height: 25),
                      // --- Próximas Citas ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Próximas Citas",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_month,
                                color: Color(0xFFFF4C79), size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestoreService.getCitasStream(_uid!),
                        builder: (context, citasSnap) {
                          if (citasSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFF4C79)));
                          }
                          final citas = citasSnap.data?.docs ??
                              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                          if (citas.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  "No tienes citas próximas.\nPresiona + para agregar una.",
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: citas.map((doc) {
                              final data = doc.data();
                              return _buildCitaCard(
                                data['fecha'] ?? '',
                                data['hora'] ?? '',
                                data['motivo'] ?? '',
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirMenuAgregar,
        backgroundColor: const Color(0xFF6B5DE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildMedicationCard(
      String time, String title, String subtitle, String docId, String status, DateTime? fechaHora) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'TOMADO':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'TOMADO';
        break;
      case 'POSPUESTO':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_outline;
        statusLabel = 'POSPUESTO';
        break;
      case 'NO_TOMADO':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'NO TOMADO';
        break;
      default:
        statusColor = const Color(0xFF6B5DE8);
        statusIcon = Icons.radio_button_unchecked;
        statusLabel = 'PENDIENTE';
    }

    return GestureDetector(
      onTap: () => _abrirModalRecordatorioMedicamento(
        docId: docId,
        nombre: title,
        dosis: subtitle,
        fechaHora: fechaHora ?? DateTime.now(),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(height: 4),
                          Text(time,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(subtitle,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 30),
                          Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitaCard(String fecha, String hora, String motivo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFD6E0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4C79),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_hospital_outlined,
                          color: Color(0xFFFF4C79), size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(motivo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(fecha,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 10),
                              const Icon(Icons.access_time,
                                  size: 12, color: Color(0xFFFF4C79)),
                              const SizedBox(width: 4),
                              Text(hora,
                                  style: const TextStyle(
                                      color: Color(0xFFFF4C79),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
