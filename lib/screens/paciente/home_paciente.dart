import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'perfil_paciente.dart';
import 'agenda_paciente.dart';
import 'salud_paciente.dart';
import 'notificaciones_paciente.dart';

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

  String _todayStr() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre del medicamento",
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
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

                                await _firestoreService.addMedicamento(
                                    uid, nombre, selectedDosis!, selectedFechaHora!);

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

  Future<void> _cambiarStatus(String docId, String statusActual) async {
    if (_uid == null) return;
    final Map<String, String> ciclo = {
      'PENDIENTE': 'TOMADO',
      'TOMADO': 'POSPUESTO',
      'POSPUESTO': 'PENDIENTE',
    };
    final nuevoStatus = ciclo[statusActual] ?? 'PENDIENTE';
    try {
      await _firestoreService.updateMedicamentoStatus(_uid!, docId, nuevoStatus);
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
        leading: IconButton(
          tooltip: "Notificaciones",
          icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesPaciente()),
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
          : StreamBuilder<dynamic>(
              stream: _firestoreService.getMedicamentosStream(_uid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
                }

                final docs =
                    (snapshot.hasData && snapshot.data!.docs != null)
                        ? snapshot.data!.docs as List
                        : <dynamic>[];

                // Filtrar meds de hoy (solo los que tienen fecha asignada para hoy)
                final today = _todayStr();
                final todayDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = data['fecha'] as String?;
                  if (fecha == null) return false; // Meds sin fecha no se muestran como de hoy
                  return fecha == today;
                }).toList();

                // Calcular progreso
                final total = todayDocs.length;
                final tomados = todayDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
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
                          final data = doc.data() as Map<String, dynamic>;
                          final status =
                              (data['status'] as String?) ?? 'PENDIENTE';
                          return _buildMedicationCard(
                            data['hora'] ?? '',
                            data['nombre'] ?? '',
                            data['dosis'] ?? '',
                            doc.id,
                            status,
                          );
                        }).toList(),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalAgregarMedicamento,
        backgroundColor: const Color(0xFF6B5DE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildMedicationCard(
      String time, String title, String subtitle, String docId, String status) {
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
      default:
        statusColor = const Color(0xFF6B5DE8);
        statusIcon = Icons.radio_button_unchecked;
        statusLabel = 'PENDIENTE';
    }

    return GestureDetector(
      onTap: () => _cambiarStatus(docId, status),
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
}