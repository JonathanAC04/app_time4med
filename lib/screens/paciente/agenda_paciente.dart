import 'package:flutter/material.dart';
import 'receta_medica_screen.dart';

class AgendaPaciente extends StatefulWidget {
  const AgendaPaciente({Key? key}) : super(key: key);

  @override
  _AgendaPacienteState createState() => _AgendaPacienteState();
}

class _AgendaPacienteState extends State<AgendaPaciente> {
  int _selectedDay = 24;
  int _currentMonth = 5;
  int _currentYear = 2024;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("CALENDARIO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => _showSnackBar("No tienes nuevas notificaciones."),
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
                      }),
                      child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.chevron_left, size: 20))),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_currentMonth == 12) { _currentMonth = 1; _currentYear++; } else { _currentMonth++; }
                        _selectedDay = 1;
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

            // Lista de Horarios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("HORARIOS - ${_getMonthShort(_currentMonth)} $_selectedDay", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                GestureDetector(
                  onTap: () => _showSnackBar("Mostrando todos los horarios del mes."),
                  child: const Text("Ver todos", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Tarjetas de medicamentos (tapeables → RecetaMédica)
            _buildAgendaCard("08:00 AM", "Atorvastatina", "Dosis: 1 comprimido (20mg)", "Tomado", Icons.check_circle_outline, Colors.black),
            _buildAgendaCard("14:30 PM", "Ibuprofeno 600", "Dosis: 1 cápsula blanda", "Pospuesto", Icons.error_outline, Colors.black),
            _buildAgendaCard("21:00 PM", "Metformina", "Dosis: 1 comprimido (850mg)", "Pendiente", Icons.timer_outlined, const Color(0xFF6B5DE8), isSelected: true),

            const SizedBox(height: 20),

            // Botón: Ver receta actual
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RecetaMedicaScreen()));
                },
                child: const Text("Ver receta actual", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),

            // Tarjeta de progreso
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(15)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF6B5DE8), size: 40),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Progreso de hoy", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
                        Text("Has completado el 66% de tu tratamiento diario.", style: TextStyle(color: Color(0xFF6B5DE8), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
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
              final bool isSelected = day == _selectedDay;
              return GestureDetector(
                onTap: day != null ? () => setState(() => _selectedDay = day) : null,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B5DE8) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day?.toString() ?? '',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildAgendaCard(String time, String title, String subtitle, String status, IconData statusIcon, Color statusColor, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const RecetaMedicaScreen()));
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