import 'package:flutter/material.dart';

class SaludPaciente extends StatelessWidget {
  const SaludPaciente({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selector de Periodo
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PERIODO ACTUAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("DICIEMBRE 2023", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)), child: const Text("Cambiar", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tarjeta Cumplimiento Total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  children: [
                    Text("CUMPLIMIENTO TOTAL", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("85", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Color(0xFF6B5DE8))),
                        Text("%", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF6B5DE8))),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("¡Excelente trabajo! Estás muy\ncerca de tu meta mensual.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Días de Racha
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [const Icon(Icons.local_fire_department, color: Colors.redAccent), const SizedBox(width: 5), const Text("Días de Racha", style: TextStyle(fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 15),
                          const Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text("12", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)), SizedBox(width: 5), Text("días seguidos", style: TextStyle(color: Colors.grey))]),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFE4E1), borderRadius: BorderRadius.circular(10)), child: const Text("¡Nivel Experto!", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    // Mascota guardián
                    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(15)), child: const Column(children: [Icon(Icons.pets, size: 40, color: Colors.brown), SizedBox(height: 5), Text("TU GUARDIÁN", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))]))
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Resumen Semanal
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(Icons.check_circle_outline, color: Color(0xFF6B5DE8), size: 20), SizedBox(width: 8), Text("RESUMEN SEMANAL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))]),
                  Text("Actualizado hoy 08:30 AM", style: TextStyle(color: Color(0xFF6B5DE8), fontSize: 10)),
                ],
              ),
              const SizedBox(height: 15),
              _buildResumenRow(Icons.medication, "Dosis tomadas", "24", "/ 28"),
              _buildResumenRow(Icons.calendar_month, "Días completos", "6", "/ 7"),
              
              const SizedBox(height: 30),
              const Text("Hoy es Viernes, 15 de Diciembre", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenRow(IconData icon, String title, String val1, String val2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF6B5DE8), size: 20)),
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