import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'detalle_doctor_view.dart';

class DoctoresAdminView extends StatefulWidget {
  const DoctoresAdminView({Key? key}) : super(key: key);

  @override
  State<DoctoresAdminView> createState() => _DoctoresAdminViewState();
}

class _DoctoresAdminViewState extends State<DoctoresAdminView> {
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

  String _messageFromException(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'El correo ya está en uso. Usa un correo diferente.';
        case 'weak-password':
          return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
        case 'invalid-email':
          return 'El correo ingresado no es válido.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet e inténtalo nuevamente.';
        default:
          return error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'No se pudo crear el doctor (Auth: ${error.code}).';
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para guardar el perfil del doctor en Firestore.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet e inténtalo nuevamente.';
        default:
          return error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'No se pudo guardar el perfil del doctor (Firestore: ${error.code}).';
      }
    }
    return 'Error inesperado al crear doctor: $error';
  }

  Future<void> _showCreateDoctorDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final especialidadCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !loading,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Dar de alta doctor'),
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
                  TextFormField(
                    controller: especialidadCtrl,
                    decoration: const InputDecoration(labelText: 'Especialidad'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                    keyboardType: TextInputType.phone,
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
                        await _authService.createUserFromAdmin(
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text.trim(),
                          profileData: {
                          'nombre': nombreCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'telefono': telefonoCtrl.text.trim(),
                          'especialidad': especialidadCtrl.text.trim(),
                          'rol': 'doctor',
                          'role': 'doctor',
                          'createdBy': FirebaseAuth.instance.currentUser?.uid,
                          'fechaRegistro': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                          },
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Doctor creado correctamente.'),
                            backgroundColor: Color(0xFF6B5DE8),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        if (kDebugMode) {
                          debugPrint('Crear doctor FirebaseAuthException: ${e.code} ${e.message}');
                        }
                        setDialogState(() => loading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_messageFromException(e)), backgroundColor: Colors.red),
                        );
                      } on FirebaseException catch (e) {
                        if (kDebugMode) {
                          debugPrint('Crear doctor FirebaseException: ${e.code} ${e.message}');
                        }
                        setDialogState(() => loading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_messageFromException(e)), backgroundColor: Colors.red),
                        );
                      } catch (e) {
                        if (kDebugMode) {
                          debugPrint('Crear doctor error inesperado: $e');
                        }
                        setDialogState(() => loading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_messageFromException(e)), backgroundColor: Colors.red),
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
          'Gestión de Doctores',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.streamUsersByRole('doctor'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((doc) {
                final data = doc.data();
                final nombre = ((data['nombre'] as String?) ?? '').toLowerCase();
                final especialidad = ((data['especialidad'] as String?) ?? '').toLowerCase();
                return _query.isEmpty || nombre.contains(_query) || especialidad.contains(_query);
              })
              .toList()
            ..sort((a, b) {
              final aName = ((a.data()['nombre'] as String?) ?? '').toLowerCase();
              final bName = ((b.data()['nombre'] as String?) ?? '').toLowerCase();
              return aName.compareTo(bName);
            });

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
                        _buildStatBadge('Total', docs.length.toString(), Icons.medical_services_outlined, Colors.white),
                        const SizedBox(width: 10),
                        _buildStatBadge('Con especialidad', docs.where((d) => ((d.data()['especialidad'] as String?) ?? '').trim().isNotEmpty).length.toString(), Icons.badge_outlined, Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Buscar doctor o especialidad...',
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
                          'No hay doctores registrados',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final nombre = (data['nombre'] as String?) ?? 'Doctor';
                          final especialidad = (data['especialidad'] as String?) ?? 'Sin especialidad';
                          final email = (data['email'] as String?) ?? '';
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
                                  const SizedBox(height: 2),
                                  Text(especialidad, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleDoctorView(doctorId: doc.id),
                                ),
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
        onPressed: _showCreateDoctorDialog,
        backgroundColor: const Color(0xFF6B5DE8),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text(
          'Dar de alta doctor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
