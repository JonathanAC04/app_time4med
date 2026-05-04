import 'package:flutter/material.dart';

class SaludPaciente extends StatefulWidget {
  const SaludPaciente({Key? key}) : super(key: key);

  @override
  _SaludPacienteState createState() => _SaludPacienteState();
}

class _SaludPacienteState extends State<SaludPaciente> {
  static const List<String> _guardianes = [
    '🐶', '🐱', '🐻', '🐼', '🦁', '🐯', '🦊', '🐺', '🦝', '🐸',
  ];
  static const List<String> _nombresGuardianes = [
    'Perro', 'Gato', 'Oso', 'Panda', 'León', 'Tigre', 'Zorro', 'Lobo', 'Mapache', 'Rana',
  ];

  int _guardianIndex = 0;

  static const List<String> _meses = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
  ];

  late String _periodoActual;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodoActual = "${_meses[now.month - 1]} ${now.year}";
  }

  List<String> _generarPeriodos() {
    final now = DateTime.now();
    final List<String> periodos = [];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      periodos.add("${_meses[date.month - 1]} ${date.year}");
    }
    return periodos;
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

  void _abrirCambiarGuardian() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Elige tu Guardián",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Tu guardián te acompaña en tu racha de adherencia",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            GridView.builder(
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
                    color: _guardianIndex == i
                        ? const Color(0xFFF3F0FF)
                        : const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _guardianIndex == i
                          ? const Color(0xFF6B5DE8)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(_guardianes[i],
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _abrirCambiarPeriodo() {
    final List<String> periodos = _generarPeriodos();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Seleccionar Período", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...periodos.map((p) => ListTile(
              title: Text(p),
              trailing: _periodoActual == p ? const Icon(Icons.check, color: Color(0xFF6B5DE8)) : null,
              onTap: () {
                setState(() => _periodoActual = p);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _abrirAgregarMetrica() {
    final glucosaController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  const Text("Registrar Métrica", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              const Text("Añade tu nivel de glucosa actual", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: glucosaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Nivel de glucosa (mg/dL)",
                  prefixIcon: Icon(Icons.water_drop_outlined, color: Color(0xFF6B5DE8)),
                  suffixText: "mg/dL",
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5DE8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final valor = glucosaController.text.trim();
                          if (valor.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Por favor ingresa un valor"), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          setModalState(() => isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 500));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) _showSnackBar("✅ Glucosa registrada: $valor mg/dL");
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Guardar Registro", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PERIODO ACTUAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(_periodoActual, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    GestureDetector(
                      onTap: _abrirCambiarPeriodo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                        child: const Text("Cambiar", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
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

              // Días de Racha + Guardián
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
                    // Mascota guardián con opción de cambio
                    GestureDetector(
                      onTap: _abrirCambiarGuardian,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFFFD6E0)),
                        ),
                        child: Column(
                          children: [
                            Text(_guardianes[_guardianIndex],
                                style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 5),
                            Text("TU GUARDIÁN", style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Cambiar", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Resumen Semanal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [Icon(Icons.check_circle_outline, color: Color(0xFF6B5DE8), size: 20), SizedBox(width: 8), Text("RESUMEN SEMANAL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))]),
                  Text("Período: $_periodoActual", style: const TextStyle(color: Color(0xFF6B5DE8), fontSize: 10)),
                ],
              ),
              const SizedBox(height: 15),
              _buildResumenRow(Icons.medication, "Dosis tomadas", "24", "/ 28"),
              _buildResumenRow(Icons.calendar_month, "Días completos", "6", "/ 7"),
              _buildResumenRow(Icons.trending_up, "Racha actual", "12", "días"),
              _buildResumenRow(Icons.star_outline, "Cumplimiento", "85", "%"),

              const SizedBox(height: 80), // Espacio para el FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAgregarMetrica,
        backgroundColor: const Color(0xFF6B5DE8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Añadir glucosa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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