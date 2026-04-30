import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'perfil_paciente.dart'; // Importamos la nueva pantalla de perfil
import 'agenda_paciente.dart'; // NUEVO
import 'salud_paciente.dart';

class HomePaciente extends StatefulWidget {
  const HomePaciente({Key? key}) : super(key: key);

  @override
  _HomePacienteState createState() => _HomePacienteState();
}

class _HomePacienteState extends State<HomePaciente> {
  int _selectedIndex = 0;

  // ¡AQUÍ CONECTAMOS TODAS LAS PANTALLAS NUEVAS!
  final List<Widget> _pantallas = [
    const _MiDiaView(),      // Pantalla 0 (Inicio)
    const AgendaPaciente(),  // Pantalla 1 (Calendario)
    const SaludPaciente(),   // Pantalla 2 (Salud)
    const PerfilPaciente(),  // Pantalla 3 (Perfil)
  ];

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
  const _MiDiaView({Key? key}) : super(key: key);

  @override
  _MiDiaViewState createState() => _MiDiaViewState();
}

class _MiDiaViewState extends State<_MiDiaView> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  void _abrirModalAgregarMedicamento() {
    final nombreController = TextEditingController();
    final dosisController = TextEditingController();
    final horaController = TextEditingController();
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
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre del medicamento",
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosisController,
                    decoration: const InputDecoration(
                      labelText: "Dosis (ej. 1 tableta 20mg)",
                      prefixIcon: Icon(Icons.scale_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: horaController,
                    decoration: const InputDecoration(
                      labelText: "Hora (ej. 08:00)",
                      prefixIcon: Icon(Icons.access_time),
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
                              final dosis = dosisController.text.trim();
                              final hora = horaController.text.trim();

                              if (nombre.isEmpty || dosis.isEmpty || hora.isEmpty) {
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

                                await _firestoreService.addMedicamento(uid, nombre, dosis, hora);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(padding: EdgeInsets.all(8.0), child: CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.monitor_heart, color: Colors.white, size: 20))),
        title: const Column(children: [
          Text("HOY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text("25/02/2026", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        centerTitle: true,
        actions: [
          const Padding(padding: EdgeInsets.only(right: 15.0), child: CircleAvatar(backgroundColor: Color(0xFFEEEEEE), child: Icon(Icons.person, color: Colors.white))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de progreso
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Progreso de hoy", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Text("25%", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("1 de 4 dosis", style: TextStyle(color: Color(0xFF6B5DE8), fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: const LinearProgressIndicator(value: 0.25, minHeight: 8, backgroundColor: Colors.white, color: Color(0xFF6B5DE8))),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text("Próximas Tomas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (_uid == null)
              const Center(child: Text("Inicia sesión para ver tus medicamentos.", style: TextStyle(color: Colors.grey)))
            else
              StreamBuilder(
                stream: _firestoreService.getMedicamentosStream(_uid!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "No tienes medicamentos registrados.\nPresiona + para agregar uno.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return Column(
                    children: docs.map((doc) {
                      final rawData = doc.data();
                      if (rawData == null) return const SizedBox.shrink();
                      final data = rawData as Map<String, dynamic>;
                      return _buildMedicationCard(
                        data['hora'] ?? '',
                        data['nombre'] ?? '',
                        data['dosis'] ?? '',
                        "PENDIENTE",
                        Colors.indigoAccent,
                        Icons.radio_button_unchecked,
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 60), // Espacio para el botón flotante
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalAgregarMedicamento,
        backgroundColor: const Color(0xFF6B5DE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildMedicationCard(String time, String title, String subtitle, String status, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(height: 4), Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(width: 20),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13))])),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))]),
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