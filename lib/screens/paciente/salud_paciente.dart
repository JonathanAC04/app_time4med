import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_helpers.dart';

class SaludPaciente extends StatefulWidget {
  const SaludPaciente({Key? key}) : super(key: key);

  @override
  _SaludPacienteState createState() => _SaludPacienteState();
}

class _SaludPacienteState extends State<SaludPaciente> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  static const List<String> _guardianes = [
    '🐶', '🐱', '🐻', '🐼', '🦁', '🐯', '🦊', '🐺', '🦝', '🐸',
  ];
  static const List<String> _nombresGuardianes = [
    'Perro', 'Gato', 'Oso', 'Panda', 'León', 'Tigre', 'Zorro', 'Lobo', 'Mapache', 'Rana',
  ];
  static const List<String> _meses = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
  ];

  int _guardianIndex = 0;
  late DateTime _periodoActual;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodoActual = DateTime(now.year, now.month, 1);
  }

  String get _periodoLabel => "${_meses[_periodoActual.month - 1]} ${_periodoActual.year}";

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6B5DE8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _abrirCambiarGuardian() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _guardianes.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              setState(() => _guardianIndex = i);
              Navigator.pop(ctx);
              _showSnackBar("¡Guardián cambiado a ${_nombresGuardianes[i]}!");
            },
            child: Container(
              decoration: BoxDecoration(
                color: _guardianIndex == i ? const Color(0xFFF3F0FF) : const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _guardianIndex == i ? const Color(0xFF6B5DE8) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(child: Text(_guardianes[i], style: const TextStyle(fontSize: 28))),
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> _periodosDisponibles() {
    final now = DateTime.now();
    return List<DateTime>.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );
  }

  void _abrirCambiarPeriodo() {
    final periodos = _periodosDisponibles();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: periodos.map((p) {
            final label = "${_meses[p.month - 1]} ${p.year}";
            final selected = p.year == _periodoActual.year && p.month == _periodoActual.month;
            return ListTile(
              title: Text(label),
              trailing: selected ? const Icon(Icons.check, color: Color(0xFF6B5DE8)) : null,
              onTap: () {
                setState(() => _periodoActual = p);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  DateTime? _fechaMedicamento(Map<String, dynamic> data) {
    final timestamp = data['fechaHora'];
    if (timestamp is Timestamp) return timestamp.toDate();
    final fecha = parseDate(data['fecha'] as String?);
    if (fecha == null) return null;
    return fecha;
  }

  int _rachaActual(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> porDia = {};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = _fechaMedicamento(data);
      if (fecha == null) continue;
      final key = formatDateToString(fecha);
      porDia.putIfAbsent(key, () => <QueryDocumentSnapshot>[]).add(doc);
    }

    var streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final key = formatDateToString(cursor);
      final dayDocs = porDia[key];
      if (dayDocs == null || dayDocs.isEmpty) break;
      final completo = dayDocs.every(
        (d) => ((d.data() as Map<String, dynamic>)['status'] as String?) == 'TOMADO',
      );
      if (!completo) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("PROGRESO",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: _uid == null
          ? const Center(child: Text("Inicia sesión para ver tu progreso."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getMedicamentosStream(_uid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
                }

                final docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
                final monthDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = _fechaMedicamento(data);
                  return fecha != null &&
                      fecha.year == _periodoActual.year &&
                      fecha.month == _periodoActual.month;
                }).toList();

                final totalDosis = monthDocs.length;
                final dosisTomadas = monthDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] as String?) == 'TOMADO';
                }).length;
                final cumplimiento = totalDosis > 0 ? ((dosisTomadas / totalDosis) * 100).round() : 0;

                final Map<String, List<QueryDocumentSnapshot>> porDia = {};
                for (final doc in monthDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = _fechaMedicamento(data);
                  if (fecha == null) continue;
                  final key = formatDateToString(fecha);
                  porDia.putIfAbsent(key, () => <QueryDocumentSnapshot>[]).add(doc);
                }
                final diasCompletos = porDia.values.where((dayDocs) {
                  return dayDocs.every((d) => ((d.data() as Map<String, dynamic>)['status'] as String?) == 'TOMADO');
                }).length;
                final racha = _rachaActual(docs);
                final totalDiasMes = DateTime(_periodoActual.year, _periodoActual.month + 1, 0).day;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("PERIODO ACTUAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(_periodoLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            TextButton(onPressed: _abrirCambiarPeriodo, child: const Text("Cambiar")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text("CUMPLIMIENTO TOTAL", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text("$cumplimiento", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Color(0xFF6B5DE8))),
                                const Text("%", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF6B5DE8))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              totalDosis > 0
                                  ? "Has tomado $dosisTomadas de $totalDosis dosis este mes."
                                  : "Aún no tienes dosis registradas este mes.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.local_fire_department, color: Colors.redAccent),
                                    const SizedBox(width: 5),
                                    const Text("Días de Racha", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ]),
                                  const SizedBox(height: 15),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text("$racha", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 5),
                                      const Text("días seguidos", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _abrirCambiarGuardian,
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F5),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFFFFD6E0)),
                                ),
                                child: Text(_guardianes[_guardianIndex], style: const TextStyle(fontSize: 36)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(children: [
                            Icon(Icons.check_circle_outline, color: Color(0xFF6B5DE8), size: 20),
                            SizedBox(width: 8),
                            Text("RESUMEN MENSUAL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ]),
                          Text("Período: $_periodoLabel", style: const TextStyle(color: Color(0xFF6B5DE8), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildResumenRow(Icons.medication, "Dosis tomadas", "$dosisTomadas", "/ $totalDosis"),
                      _buildResumenRow(Icons.calendar_month, "Días completos", "$diasCompletos", "/ $totalDiasMes"),
                      _buildResumenRow(Icons.trending_up, "Racha actual", "$racha", "días"),
                      _buildResumenRow(Icons.star_outline, "Cumplimiento", "$cumplimiento", "%"),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildResumenRow(IconData icon, String title, String val1, String val2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF6B5DE8), size: 20),
          ),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(val1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 5),
          Text(val2, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
