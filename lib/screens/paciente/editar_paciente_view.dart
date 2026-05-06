import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class EditarPacienteView extends StatefulWidget {
  const EditarPacienteView({Key? key}) : super(key: key);

  @override
  _EditarPacienteViewState createState() => _EditarPacienteViewState();
}

class _EditarPacienteViewState extends State<EditarPacienteView> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _pesoController = TextEditingController();
  final _estaturaController = TextEditingController();
  final _contactoEmergenciaNombreController = TextEditingController();
  final _contactoEmergenciaTelController = TextEditingController();
  late final TextEditingController _fechaNacimientoController;

  String _sexo = "Masculino";
  String _tipoSangre = "O+";
  DateTime? _fechaNacimiento;
  double? _imc;
  bool _isSaving = false;

  static const List<String> _sexoOpciones = ["Masculino", "Femenino", "Otro"];
  static const List<String> _tiposSangre = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  @override
  void initState() {
    super.initState();
    _fechaNacimientoController = TextEditingController(text: "Seleccionar");
    _pesoController.addListener(_calcularIMC);
    _estaturaController.addListener(_calcularIMC);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (_uid == null) return;
    final data = await _firestoreService.getUserData(_uid!);
    if (data == null || !mounted) return;

    _nombreController.text = (data['nombre'] as String?) ?? '';
    _apellidosController.text = (data['apellidos'] as String?) ?? '';
    _sexo = (data['sexo'] as String?) ?? _sexo;
    _tipoSangre = (data['tipoSangre'] as String?) ?? _tipoSangre;
    _pesoController.text = data['peso']?.toString() ?? '';
    _estaturaController.text = data['estatura']?.toString() ?? '';
    _contactoEmergenciaNombreController.text = (data['contactoEmergenciaNombre'] as String?) ?? '';
    _contactoEmergenciaTelController.text = (data['contactoEmergenciaTelefono'] as String?) ?? '';

    final fechaRaw = (data['fechaNacimiento'] as String?) ?? '';
    if (fechaRaw.isNotEmpty) {
      final parts = fechaRaw.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null && d > 0 && m > 0 && m <= 12) {
          final parsed = DateTime(y, m, d);
          if (parsed.year == y && parsed.month == m && parsed.day == d) {
            _fechaNacimiento = parsed;
          }
        }
      }
    }
    _fechaNacimientoController.text = _formatFecha(_fechaNacimiento);
    _calcularIMC();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _pesoController.dispose();
    _estaturaController.dispose();
    _contactoEmergenciaNombreController.dispose();
    _contactoEmergenciaTelController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  void _calcularIMC() {
    final peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
    final estatura = double.tryParse(_estaturaController.text.replaceAll(',', '.'));
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

  String _formatFecha(DateTime? d) {
    if (d == null) return "Seleccionar";
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        _fechaNacimientoController.text = _formatFecha(picked);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate() || _uid == null) return;
    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateUserData(_uid!, {
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'sexo': _sexo,
        'tipoSangre': _tipoSangre,
        'peso': double.tryParse(_pesoController.text.replaceAll(',', '.')),
        'estatura': double.tryParse(_estaturaController.text.replaceAll(',', '.')),
        'fechaNacimiento': _formatFecha(_fechaNacimiento),
        'contactoEmergenciaNombre': _contactoEmergenciaNombreController.text.trim(),
        'contactoEmergenciaTelefono': _contactoEmergenciaTelController.text.trim(),
        'imc': _imc,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Datos actualizados correctamente"), backgroundColor: Color(0xFF6B5DE8)),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Datos del Paciente",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _guardarCambios,
            child: const Text("Guardar",
                style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _field(_nombreController, "Nombre"),
              const SizedBox(height: 12),
              _field(_apellidosController, "Apellidos"),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sexo,
                decoration: const InputDecoration(labelText: "Sexo"),
                items: _sexoOpciones
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _sexo = v ?? _sexo),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _seleccionarFechaNacimiento,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _fechaNacimientoController,
                    decoration: const InputDecoration(labelText: "Fecha de Nacimiento"),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoSangre,
                decoration: const InputDecoration(labelText: "Tipo de Sangre"),
                items: _tiposSangre
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoSangre = v ?? _tipoSangre),
              ),
              const SizedBox(height: 12),
              _field(_pesoController, "Peso (kg)", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              _field(_estaturaController, "Estatura (m)", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              if (_imc != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("IMC: ${_imc!.toStringAsFixed(1)} (${_clasificacionIMC(_imc!)})"),
                ),
              ],
              const SizedBox(height: 12),
              _field(_contactoEmergenciaNombreController, "Nombre contacto emergencia", requiredField: false),
              const SizedBox(height: 12),
              _field(_contactoEmergenciaTelController, "Teléfono emergencia", requiredField: false),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8)),
                  onPressed: _isSaving ? null : _guardarCambios,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Guardar Cambios", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {TextInputType? keyboardType, bool requiredField = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: requiredField
          ? (v) => (v == null || v.trim().isEmpty) ? "Campo requerido" : null
          : null,
      decoration: InputDecoration(labelText: label),
    );
  }
}
