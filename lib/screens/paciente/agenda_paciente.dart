import 'package:flutter/material.dart';
import 'receta_medica_screen.dart';

class AgendaPaciente extends StatelessWidget {
  const AgendaPaciente({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("CALENDARIO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {})],
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MES ACTUAL", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("Mayo 2024", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.chevron_left, size: 20))),
                    const SizedBox(width: 10),
                    Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.chevron_right, size: 20))),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // Simulación del Calendario (Layout en Grid)
            _buildCalendario(),
            const SizedBox(height: 30),

            // Lista de Horarios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("HORARIOS - MAYO 24", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const Text("Ver todos", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),

            // Tarjetas de medicamentos
            _buildAgendaCard("08:00 AM", "Atorvastatina", "Dosis: 1 comprimido (20mg)", "Tomado", Icons.check_circle_outline, Colors.black),
            _buildAgendaCard("14:30 PM", "Ibuprofeno 600", "Dosis: 1 cápsula blanda", "Pospuesto", Icons.error_outline, Colors.black),
            _buildAgendaCard("21:00 PM", "Metformina", "Dosis: 1 comprimido (850mg)", "Pendiente", Icons.timer_outlined, const Color(0xFF6B5DE8), isSelected: true),
            
            const SizedBox(height: 20),

            // Botón: Ver receta actual (NAVEGACIÓN A LA IMAGEN 8)
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
              decoration: BoxDecoration(color: const Color(0xFFF0F8FF), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue, size: 40),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Progreso de hoy", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Text("Has completado el 66% de tu tratamiento diario.", style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Espacio para FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendario() {
    // Es una simulación rápida del layout del calendario de tu diseño
    List<String> dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: dias.map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))).toList()),
        const SizedBox(height: 15),
        // Aquí simulamos la semana donde está el día 24 seleccionado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [22, 23, 24, 25, 26, 27, 28].map((dia) {
            bool isSelected = dia == 24;
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: isSelected ? const BoxDecoration(color: Colors.blue, shape: BoxShape.circle) : null,
              child: Text(dia.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : null)),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildAgendaCard(String time, String title, String subtitle, String status, IconData statusIcon, Color statusColor, {bool isSelected = false}) {
    return Container(
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
    );
  }
}