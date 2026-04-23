import 'package:flutter/material.dart';

class RecetaMedicaScreen extends StatelessWidget {
  const RecetaMedicaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFF6B5DE8)),
            const SizedBox(width: 8),
            const Text("RECETA MÉDICA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta del Doctor
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF9F9FF), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=150&q=80')),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("MÉDICO ASIGNADO", style: TextStyle(color: Color(0xFF6B5DE8), fontSize: 10, fontWeight: FontWeight.bold)),
                            const Text("Dr. Alejandro Sanz", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const Text("Especialista en Cardiología", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8E5FF), borderRadius: BorderRadius.circular(10)), child: const Text("ID: #88293", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn("PACIENTE", "Carlos Méndez", Icons.person_outline),
                      _buildInfoColumn("FECHA DE EMISIÓN", "24 Mayo, 2024", Icons.calendar_today),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Medicamentos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("3 items", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),

            // Lista de medicinas de la receta
            _buildRecetaItem("Atorvastatina", "1 comprimido (20mg)", "Cada 24 horas (Noche)", "30 días (Hasta 23 Jun)"),
            _buildRecetaItem("Ibuprofeno 600", "1 cápsula blanda", "Cada 8 horas (Si hay dolor)", "7 días (Hasta 31 May)"),
            _buildRecetaItem("Metformina", "1 comprimido (850mg)", "Con el desayuno", "Crónico"),

            const SizedBox(height: 20),

            // Alerta de guardado
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFFE8F8F5), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cambios guardados", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        Text("La receta ha sido actualizada correctamente.", style: TextStyle(color: Colors.teal, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botones de abajo
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.save, color: Colors.white), label: const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontSize: 16)), onPressed: () {})),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.share, color: Colors.black), label: const Text("Compartir Receta", style: TextStyle(color: Colors.black, fontSize: 16)), onPressed: () {})),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String titulo, String valor, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(icono, size: 14, color: const Color(0xFF6B5DE8)),
            const SizedBox(width: 5),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        )
      ],
    );
  }

  Widget _buildRecetaItem(String titulo, String dosis, String frec, String duracion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.grey),
          const SizedBox(width: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF3F0FF), shape: BoxShape.circle), child: const Icon(Icons.medication_outlined, color: Color(0xFF6B5DE8))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(dosis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(frec, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Row(children: [const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6B5DE8)), const SizedBox(width: 4), Text(duracion, style: const TextStyle(color: Color(0xFF6B5DE8), fontSize: 12, fontWeight: FontWeight.bold))]),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }
}