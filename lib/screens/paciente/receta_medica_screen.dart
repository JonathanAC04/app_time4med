import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'notificaciones_paciente.dart';

class RecetaMedicaScreen extends StatefulWidget {
  final VoidCallback? onGoToProfile;

  const RecetaMedicaScreen({this.onGoToProfile, Key? key}) : super(key: key);

  @override
  _RecetaMedicaScreenState createState() => _RecetaMedicaScreenState();
}

class _RecetaMedicaScreenState extends State<RecetaMedicaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic>? _userData;
  bool _loadingUser = true;

  static const List<String> _dosisOpciones = [
    '1 tableta (10mg)',
    '1 tableta (20mg)',
    '1 tableta (50mg)',
    '1 tableta (100mg)',
    '1 cápsula (250mg)',
    '1 cápsula (500mg)',
    '1 comprimido (10mg)',
    '1 comprimido (850mg)',
    '5ml jarabe',
    '10ml jarabe',
    '1 inyección',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_uid != null) {
      final data = await _firestoreService.getUserData(_uid!);
      if (mounted) {
        setState(() {
          _userData = data;
          _loadingUser = false;
        });
      }
    } else {
      setState(() => _loadingUser = false);
    }
  }

  void _showSnackBar(String message, {Color color = const Color(0xFF6B5DE8)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _editarMedicamento(String docId, Map<String, dynamic> data) {
    final nombreController = TextEditingController(text: data['nombre'] ?? '');
    String? selectedDosis = _dosisOpciones.contains(data['dosis'])
        ? data['dosis'] as String
        : null;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  const Text("Editar Medicamento",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
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
              DropdownButtonFormField<String>(
                value: selectedDosis,
                decoration: const InputDecoration(
                  labelText: "Dosis",
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                items: _dosisOpciones
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedDosis = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5DE8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final nombre = nombreController.text.trim();
                          if (nombre.isEmpty || selectedDosis == null) {
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
                            await _firestoreService.updateMedicamento(
                                _uid!, docId, {
                              'nombre': nombre,
                              'dosis': selectedDosis,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) _showSnackBar("✅ Medicamento actualizado correctamente");
                          } catch (e) {
                            setModalState(() => isLoading = false);
                            if (mounted) {
                              _showSnackBar("❌ Error al guardar: $e", color: Colors.red);
                            }
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Guardar cambios",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(String docId, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar medicamento",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            "¿Está seguro de borrar el medicamento \"$nombre\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteMedicamento(_uid!, docId);
                if (mounted) _showSnackBar("✅ Medicamento eliminado correctamente");
              } catch (e) {
                if (mounted) {
                  _showSnackBar("❌ Error al eliminar: $e", color: Colors.red);
                }
              }
            },
            child: const Text("Eliminar",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medico = _userData?['medico'] as Map<String, dynamic>?;
    final pacienteNombre = _userData?['nombre'] as String? ?? 'Paciente';
    final now = DateTime.now();
    final fechaEmision =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFF6B5DE8)),
            const SizedBox(width: 8),
            const Text("RECETA MÉDICA",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ],
        ),
        centerTitle: true,
      ),
      body: _loadingUser
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5DE8)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Tarjeta de médico/paciente
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FF),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        // Sección del médico (solo si existe)
                        if (medico != null) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFFE8E5FF),
                                child: Text(
                                  (medico['nombre'] as String? ?? 'M')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF6B5DE8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("MÉDICO ASIGNADO",
                                        style: TextStyle(
                                            color: Color(0xFF6B5DE8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        medico['nombre'] as String? ??
                                            'Dr. Sin nombre',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    Text(
                                        medico['especialidad'] as String? ?? '',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (medico['id'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE8E5FF),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text("ID: #${medico['id']}",
                                      style: const TextStyle(
                                          color: Color(0xFF6B5DE8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                            ],
                          ),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Divider()),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn(
                                "PACIENTE", pacienteNombre, Icons.person_outline),
                            _buildInfoColumn("FECHA DE EMISIÓN", fechaEmision,
                                Icons.calendar_today),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Lista de medicamentos desde Firestore
                  if (_uid == null)
                    const Center(
                        child: Text("Inicia sesión para ver tus medicamentos.",
                            style: TextStyle(color: Colors.grey)))
                  else
                    StreamBuilder<dynamic>(
                      stream: _firestoreService.getMedicamentosStream(_uid!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF6B5DE8)));
                        }
                        final docs = (snapshot.hasData &&
                                snapshot.data != null)
                            ? snapshot.data!.docs as List
                            : <dynamic>[];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Medicamentos",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text("${docs.length} items",
                                    style:
                                        const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            if (docs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "No tienes medicamentos registrados.",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ),
                              )
                            else
                              ...docs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                return _buildRecetaItem(
                                  doc.id,
                                  data['nombre'] ?? 'Sin nombre',
                                  data['dosis'] ?? '',
                                  data['hora'] ?? '',
                                  data['fecha'] ?? '',
                                  data,
                                );
                              }).toList(),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // Botón compartir
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.share, color: Colors.black),
                      label: const Text("Compartir Receta",
                          style:
                              TextStyle(color: Colors.black, fontSize: 16)),
                      onPressed: () {
                        _showSnackBar(
                            "📤 Compartir receta: función disponible próximamente");
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoColumn(String titulo, String valor, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(icono, size: 14, color: const Color(0xFF6B5DE8)),
            const SizedBox(width: 5),
            Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        )
      ],
    );
  }

  Widget _buildRecetaItem(String docId, String titulo, String dosis,
      String hora, String fecha, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF), shape: BoxShape.circle),
            child: const Icon(Icons.medication_outlined,
                color: Color(0xFF6B5DE8)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (dosis.isNotEmpty)
                  Text(dosis,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                if (hora.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Color(0xFF6B5DE8)),
                      const SizedBox(width: 4),
                      Text(hora,
                          style: const TextStyle(
                              color: Color(0xFF6B5DE8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      if (fecha.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(fecha,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                tooltip: "Editar",
                onPressed: _uid != null
                    ? () => _editarMedicamento(docId, data)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: "Eliminar",
                onPressed: _uid != null
                    ? () => _confirmarEliminar(docId, titulo)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}