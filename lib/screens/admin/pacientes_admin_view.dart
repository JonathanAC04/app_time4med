import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'detalle_paciente_view.dart';

class PacientesAdminView extends StatefulWidget {
  const PacientesAdminView({Key? key}) : super(key: key);

  @override
  State<PacientesAdminView> createState() => _PacientesAdminViewState();
}

class _PacientesAdminViewState extends State<PacientesAdminView> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreatePatientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final edadCtrl = TextEditingController();
    DateTime? fechaNacimiento;
    String sexo = 'Masculino';
    bool loading = false;

    String fechaLabel() {
      if (fechaNacimiento == null) return 'Seleccionar fecha de nacimiento';
      return '${fechaNacimiento!.day.toString().padLeft(2, '0')}/${fechaNacimiento!.month.toString().padLeft(2, '0')}/${fechaNacimiento!.year}';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Dar de alta paciente'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Campo obligatorio';
                      return value.contains('@') ? null : 'Correo inválido';
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña temporal'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Campo obligatorio';
                      return value.length < 6 ? 'Mínimo 6 caracteres' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: sexo,
                    items: const [
                      DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                      DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => sexo = value);
                    },
                    decoration: const InputDecoration(labelText: 'Sexo'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: edadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad (opcional)'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF6B5DE8)),
                      label: Text(fechaLabel()),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaNacimiento ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked == null) return;
                        setDialogState(() => fechaNacimiento = picked);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);
                      try {
                        final uid = await _authService.createUserFromAdmin(
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text.trim(),
                        );
                        await _firestoreService.setUserProfile(uid, {
                          'nombre': nombreCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'sexo': sexo,
                          'edad': int.tryParse(edadCtrl.text.trim()),
                          'fechaNacimiento': fechaNacimiento == null
                              ? ''
                              : '${fechaNacimiento!.day.toString().padLeft(2, '0')}/${fechaNacimiento!.month.toString().padLeft(2, '0')}/${fechaNacimiento!.year}',
                          'rol': 'paciente',
                          'role': 'patient',
                          'createdBy': FirebaseAuth.instance.currentUser?.uid,
                          'fechaRegistro': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Paciente creado correctamente.'),
                            backgroundColor: Color(0xFF6B5DE8),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        String message = 'No se pudo crear el paciente.';
                        if (e.code == 'email-already-in-use') {
                          message = 'El correo ya está en uso.';
                        } else if (e.code == 'weak-password') {
                          message = 'La contraseña es demasiado débil.';
                        } else if (e.message != null && e.message!.isNotEmpty) {
                          message = e.message!;
                        }
                        setDialogState(() => loading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), backgroundColor: Colors.red),
                        );
                      } catch (_) {
                        setDialogState(() => loading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error inesperado al crear paciente.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignDoctorDialog({required String patientId}) async {
    final doctorsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'doctor')
        .get();

    if (!mounted) return;
    if (doctorsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay doctores disponibles para asignar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedDoctorId;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Asignar doctor'),
          content: DropdownButtonFormField<String>(
            value: selectedDoctorId,
            hint: const Text('Selecciona un doctor'),
            isExpanded: true,
            items: doctorsSnapshot.docs.map((doc) {
              final data = doc.data();
              final nombre = (data['nombre'] as String?) ?? 'Doctor';
              final especialidad = (data['especialidad'] as String?) ?? 'Sin especialidad';
              return DropdownMenuItem(
                value: doc.id,
                child: Text('$nombre • $especialidad', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) => setDialogState(() => selectedDoctorId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _firestoreService.assignPatientToDoctor(patientId: patientId);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paciente desasignado.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Quitar asignación', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: selectedDoctorId == null
                  ? null
                  : () async {
                      final selectedDoctor = doctorsSnapshot.docs.firstWhere((doc) => doc.id == selectedDoctorId);
                      final selectedDoctorData = selectedDoctor.data();
                      final doctorName = (selectedDoctorData['nombre'] as String?) ?? '';
                      await _firestoreService.assignPatientToDoctor(
                        patientId: patientId,
                        doctorId: selectedDoctor.id,
                        doctorName: doctorName,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Paciente asignado correctamente.'),
                          backgroundColor: Color(0xFF6B5DE8),
                        ),
                      );
                    },
              child: const Text('Asignar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B5DE8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestión de Pacientes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.streamUsersByRole('paciente'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((doc) {
                final data = doc.data();
                final nombre = ((data['nombre'] as String?) ?? '').toLowerCase();
                final email = ((data['email'] as String?) ?? '').toLowerCase();
                return _query.isEmpty || nombre.contains(_query) || email.contains(_query);
              })
              .toList()
            ..sort((a, b) {
              final aName = ((a.data()['nombre'] as String?) ?? '').toLowerCase();
              final bName = ((b.data()['nombre'] as String?) ?? '').toLowerCase();
              return aName.compareTo(bName);
            });

          final asignados = docs.where((doc) => ((doc.data()['doctorId'] as String?) ?? '').trim().isNotEmpty).length;

          return Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B5DE8), Color(0xFF9B8BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatBadge('Total', docs.length.toString(), Icons.groups_outlined, Colors.white),
                        const SizedBox(width: 8),
                        _buildStatBadge('Asignados', asignados.toString(), Icons.link_outlined, Colors.greenAccent),
                        const SizedBox(width: 8),
                        _buildStatBadge('Sin asignar', (docs.length - asignados).toString(), Icons.person_off_outlined, Colors.orangeAccent),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Buscar paciente o correo...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6B5DE8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay pacientes registrados',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final nombre = (data['nombre'] as String?) ?? 'Paciente';
                          final email = (data['email'] as String?) ?? '';
                          final doctorName = (data['medico'] as String?) ?? '';
                          final hasDoctor = ((data['doctorId'] as String?) ?? '').trim().isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF6B5DE8),
                                child: Text(
                                  _initials(nombre),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (email.isNotEmpty) Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasDoctor ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hasDoctor ? '● Asignado: $doctorName' : '● Sin doctor asignado',
                                      style: TextStyle(
                                        color: hasDoctor ? Colors.green.shade700 : Colors.orange.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                tooltip: 'Asignar doctor',
                                icon: const Icon(Icons.link, color: Color(0xFF6B5DE8)),
                                onPressed: () => _showAssignDoctorDialog(patientId: doc.id),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DetallePacienteView(patientId: doc.id)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePatientDialog,
        backgroundColor: const Color(0xFF6B5DE8),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Dar de alta paciente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PA';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
