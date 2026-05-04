import 'package:flutter/material.dart';

class EditarPacienteView extends StatefulWidget {
  const EditarPacienteView({Key? key}) : super(key: key);

  @override
  _EditarPacienteViewState createState() => _EditarPacienteViewState();
}

class _EditarPacienteViewState extends State<EditarPacienteView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreController = TextEditingController(text: "Alejandro");
  final _apellidosController = TextEditingController(text: "González");
  final _pesoController = TextEditingController(text: "78.5");
  final _estaturaController = TextEditingController(text: "1.75");
  final _contactoEmergenciaNombreController =
      TextEditingController(text: "María G.");
  final _contactoEmergenciaTelController =
      TextEditingController(text: "+34 600 123 456");

  // State
  String _sexo = "Masculino";
  String _tipoSangre = "O+";
  DateTime? _fechaNacimiento = DateTime(1988, 5, 12);
  double? _imc;

  static const List<String> _sexoOpciones = ["Masculino", "Femenino", "Otro"];
  static const List<String> _tiposSangre = [
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"
  ];

  @override
  void initState() {
    super.initState();
    _calcularIMC();
    _pesoController.addListener(_calcularIMC);
    _estaturaController.addListener(_calcularIMC);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _pesoController.dispose();
    _estaturaController.dispose();
    _contactoEmergenciaNombreController.dispose();
    _contactoEmergenciaTelController.dispose();
    super.dispose();
  }

  void _calcularIMC() {
    final peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    final estatura =
        double.tryParse(_estaturaController.text.replaceAll(',', '.'));
    if (peso != null && estatura != null && estatura > 0) {
      setState(() => _imc = peso / (estatura * estatura));
    } else {
      setState(() => _imc = null);
    }
  }

  String _clasificacionIMC(double imc) {
    if (imc < 18.5) return "Bajo peso";
    if (imc < 25) return "Peso normal";
    if (imc < 30) return "Sobrepeso";
    return "Obesidad";
  }

  Color _colorIMC(double imc) {
    if (imc < 18.5) return Colors.blue;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF6B5DE8)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  String _formatFecha(DateTime? d) {
    if (d == null) return "Seleccionar";
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  void _guardarCambios() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Datos actualizados correctamente"),
        backgroundColor: const Color(0xFF6B5DE8),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Datos del Paciente",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _guardarCambios,
            child: const Text("Guardar",
                style: TextStyle(
                    color: Color(0xFF6B5DE8),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sección: Información Personal ──
              _buildSectionHeader(
                  Icons.person_outlined, "INFORMACIÓN PERSONAL"),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildTextFormField(
                    controller: _nombreController,
                    label: "Nombre",
                    icon: Icons.badge_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Campo requerido" : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextFormField(
                    controller: _apellidosController,
                    label: "Apellidos",
                    icon: Icons.badge_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Campo requerido" : null,
                  ),
                  const SizedBox(height: 14),
                  // Sexo dropdown
                  _buildDropdownField<String>(
                    label: "Sexo",
                    icon: Icons.wc_outlined,
                    value: _sexo,
                    items: _sexoOpciones,
                    onChanged: (v) => setState(() => _sexo = v!),
                  ),
                  const SizedBox(height: 14),
                  // Fecha de Nacimiento
                  GestureDetector(
                    onTap: _seleccionarFechaNacimiento,
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Fecha de Nacimiento",
                          prefixIcon: const Icon(Icons.calendar_month,
                              color: Color(0xFF6B5DE8)),
                          hintText: _formatFecha(_fechaNacimiento),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                        ),
                        controller: TextEditingController(
                            text: _formatFecha(_fechaNacimiento)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tipo de Sangre
                  _buildDropdownField<String>(
                    label: "Tipo de Sangre",
                    icon: Icons.water_drop_outlined,
                    value: _tipoSangre,
                    items: _tiposSangre,
                    onChanged: (v) => setState(() => _tipoSangre = v!),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Sección: Medidas Corporales e IMC ──
              _buildSectionHeader(
                  Icons.monitor_heart_outlined, "MEDIDAS CORPORALES"),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _pesoController,
                          label: "Peso",
                          icon: Icons.scale_outlined,
                          suffix: "kg",
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "Requerido";
                            }
                            if (double.tryParse(v.replaceAll(',', '.')) ==
                                null) {
                              return "Valor inválido";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _estaturaController,
                          label: "Estatura",
                          icon: Icons.height,
                          suffix: "m",
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "Requerido";
                            }
                            if (double.tryParse(v.replaceAll(',', '.')) ==
                                null) {
                              return "Valor inválido";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_imc != null) ...[
                    const SizedBox(height: 20),
                    // IMC Result Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _colorIMC(_imc!).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _colorIMC(_imc!).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  _colorIMC(_imc!).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.monitor_weight_outlined,
                                color: _colorIMC(_imc!), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("IMC (Índice de Masa Corporal)",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _imc!.toStringAsFixed(1),
                                      style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: _colorIMC(_imc!)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _clasificacionIMC(_imc!),
                                      style: TextStyle(
                                          color: _colorIMC(_imc!),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // ── Sección: Seguridad ──
              _buildSectionHeader(Icons.shield_outlined, "SEGURIDAD"),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildTextFormField(
                    controller: _contactoEmergenciaNombreController,
                    label: "Nombre del contacto de emergencia",
                    icon: Icons.person_pin_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextFormField(
                    controller: _contactoEmergenciaTelController,
                    label: "Teléfono de emergencia",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Botón Guardar ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text("Guardar Cambios",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5DE8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  onPressed: _guardarCambios,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6B5DE8), size: 20),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
                fontSize: 12)),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B5DE8)),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6B5DE8), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B5DE8)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6B5DE8), width: 1.5),
        ),
      ),
      items: items
          .map((item) =>
              DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
    );
  }
}
