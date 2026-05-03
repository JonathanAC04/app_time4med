import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'receta_medica_screen.dart';
import 'notificaciones_paciente.dart';

class AgendaPaciente extends StatefulWidget {
  final VoidCallback? onGoToProfile;

  const AgendaPaciente({this.onGoToProfile, Key? key}) : super(key: key);

  @override
  _AgendaPacienteState createState() => _AgendaPacienteState();
}

class _AgendaPacienteState extends State<AgendaPaciente> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  late int _selectedDay;
  late int _currentMonth;
  late int _currentYear;
  bool _showAllMonth = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = now.day;
    _currentMonth = now.month;
    _currentYear = now.year;
  }

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

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  String _getMonthShort(int month) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    return months[month - 1];
  }

  String _selectedDateStr() {
    return "${_currentYear.toString().padLeft(4, '0')}-${_currentMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}";
  }

  String _currentMonthPrefix() {
    return "${_currentYear.toString().padLeft(4, '0')}-${_currentMonth.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("CALENDARIO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del mes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MES ACTUAL", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("${_getMonthName(_currentMonth)} $_currentYear", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_currentMonth == 1) { _currentMonth = 12; _currentYear--; } else { _currentMonth--; }
                        _selectedDay = 1;
                        _showAllMonth = false;
                      }),
                      child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.chevron_left, size: 20))),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_currentMonth == 12) { _currentMonth = 1; _currentYear++; } else { _currentMonth++; }
                        _selectedDay = 1;
                        _showAllMonth = false;
                      }),
                      child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.chevron_right, size: 20))),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),

            // Calendario interactivo
            _buildCalendario(),
            const SizedBox(height: 30),

            // Encabezado de lista
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showAllMonth
                      ? "TODOS - ${_getMonthShort(_currentMonth)} $_currentYear"
                      : "HORARIOS - ${_getMonthShort(_currentMonth)} $_selectedDay",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showAllMonth = !_showAllMonth),
                  child: Text(
                    _showAllMonth ? "Ver por día" : "Ver todos",
                    style: const TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Lista dinámica de medicamentos
            if (_uid == null)
              const Center(child: Text("Inicia sesión para ver tus medicamentos.", style: TextStyle(color: Colors.grey)))
            else
              StreamBuilder<dynamic>(
                stream: _firestoreService.getMedicamentosStream(_uid!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
                  }

                  final allDocs = (snapshot.hasData && snapshot.data != null)
                      ? snapshot.data!.docs as List
                      : <dynamic>[];

                  // Filtrar por día o mes
                  List filteredDocs;
                  if (_showAllMonth) {
                    final monthPrefix = _currentMonthPrefix();
                    filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha = data['fecha'] as String?;
                      return fecha != null && fecha.startsWith(monthPrefix);
                    }).toList();
                  } else {
                    final selectedStr = _selectedDateStr();
                    filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha = data['fecha'] as String?;
                      return fecha != null && fecha == selectedStr;
                    }).toList();
                  }

                  if (filteredDocs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          _showAllMonth
                              ? "No hay medicamentos para este mes."
                              : "No hay medicamentos para este día.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = (data['status'] as String?) ?? 'PENDIENTE';
                      return _buildAgendaCard(
                        data['hora'] ?? '',
                        data['nombre'] ?? '',
                        data['dosis'] ?? '',
                        status,
                        doc.id,
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Botón: Ver receta actual
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => RecetaMedicaScreen(
                      onGoToProfile: widget.onGoToProfile,
                    ),
                  ));
                },
                child: const Text("Ver receta actual", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),

            // Tarjeta de progreso
            _uid == null
                ? const SizedBox.shrink()
                : StreamBuilder<dynamic>(
                    stream: _firestoreService.getMedicamentosStream(_uid!),
                    builder: (context, snapshot) {
                      final allDocs = (snapshot.hasData && snapshot.data != null)
                          ? snapshot.data!.docs as List
                          : <dynamic>[];
                      final selectedStr = _selectedDateStr();
                      final todayDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final fecha = data['fecha'] as String?;
                        return fecha != null && fecha == selectedStr;
                      }).toList();
                      final total = todayDocs.length;
                      final tomados = todayDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['status'] as String?) == 'TOMADO';
                      }).length;
                      final pct = total > 0 ? ((tomados / total) * 100).round() : 0;

                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF6B5DE8), size: 40),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Progreso del día seleccionado", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
                                  Text(
                                    total > 0
                                        ? "Has completado el $pct% ($tomados de $total) de tu tratamiento."
                                        : "Sin medicamentos para este día.",
                                    style: const TextStyle(color: Color(0xFF6B5DE8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSnackBar("Próximamente: agendar nueva cita médica."),
        backgroundColor: const Color(0xFF6B5DE8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendario() {
    const List<String> dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final int daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final int firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday; // 1=Mon
    final now = DateTime.now();
    final todayDay = (now.year == _currentYear && now.month == _currentMonth) ? now.day : -1;

    List<List<int?>> weeks = [];
    List<int?> currentWeek = List.filled(7, null);
    int dayOfWeek = firstWeekday - 1;

    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek[dayOfWeek] = day;
      dayOfWeek++;
      if (dayOfWeek == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
        dayOfWeek = 0;
      }
    }
    if (dayOfWeek > 0) weeks.add(currentWeek);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dias.map((d) => SizedBox(width: 35, child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))).toList(),
        ),
        const SizedBox(height: 10),
        ...weeks.map((week) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((day) {
              final bool isSelected = day == _selectedDay && !_showAllMonth;
              final bool isToday = day == todayDay;
              return GestureDetector(
                onTap: day != null ? () => setState(() {
                  _selectedDay = day;
                  _showAllMonth = false;
                }) : null,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B5DE8) : null,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF6B5DE8), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day?.toString() ?? '',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF6B5DE8)
                                : Colors.black,
                        fontWeight: (isSelected || isToday)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )),
      ],
    );
  }

  Widget _buildAgendaCard(String time, String title, String subtitle, String status, String docId) {
    Color statusColor;
    IconData statusIcon;
    bool isSelected = false;

    switch (status) {
      case 'TOMADO':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'POSPUESTO':
        statusColor = Colors.orange;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = const Color(0xFF6B5DE8);
        statusIcon = Icons.timer_outlined;
        isSelected = true;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => RecetaMedicaScreen(
            onGoToProfile: widget.onGoToProfile,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF6B5DE8) : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (isSelected) Container(width: 4, decoration: const BoxDecoration(color: Color(0xFF6B5DE8), borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.medication, color: Colors.black54)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(status, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(statusIcon, color: statusColor),
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
