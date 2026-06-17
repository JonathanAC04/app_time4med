import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Pantalla del admin para gestionar invitaciones por rol.
///
/// Funciona SIN Cloud Functions ni correos automáticos:
///   1. El admin escribe el correo de la persona y elige el rol.
///   2. Se guarda en /invites/{emailLower} con { rol, createdAt }.
///   3. Cuando esa persona inicia sesión o se registra con ESE mismo correo,
///      AuthService.applyInviteIfExists() le asigna el rol y borra el invite.
///
/// O sea: el admin "pre-asigna" el rol. La persona solo entra normal.
class InvitacionesAdminView extends StatefulWidget {
  const InvitacionesAdminView({Key? key}) : super(key: key);

  @override
  State<InvitacionesAdminView> createState() => _InvitacionesAdminViewState();
}

class _InvitacionesAdminViewState extends State<InvitacionesAdminView> {
  static const Color _violeta = Color(0xFF6B5DE8);

  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _rolSeleccionado = 'doctor';
  bool _guardando = false;

  final _invitesRef = FirebaseFirestore.instance.collection('invites');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = _violeta}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _crearInvitacion() async {
    if (!_formKey.currentState!.validate()) return;

    final emailLower = _emailCtrl.text.trim().toLowerCase();
    setState(() => _guardando = true);

    try {
      await _invitesRef.doc(emailLower).set({
        'rol': _rolSeleccionado,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _emailCtrl.clear();
      _showSnackBar('✅ Invitación creada para $emailLower');
    } catch (e) {
      _showSnackBar('❌ No se pudo crear: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminarInvitacion(String emailLower) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar invitación'),
        content: Text('¿Eliminar la invitación de $emailLower?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _invitesRef.doc(emailLower).delete();
      _showSnackBar('🗑️ Invitación eliminada.', color: Colors.orange);
    } catch (e) {
      _showSnackBar('❌ No se pudo eliminar: $e', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _violeta,
        elevation: 0,
        title: const Text('Invitaciones',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---- Explicación ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _violeta),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Asigna un rol a un correo. Cuando esa persona inicie '
                    'sesión o se registre con ese mismo correo, recibirá el '
                    'rol automáticamente.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- Formulario ----
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Correo de la persona',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Ingresa un correo';
                      if (!t.contains('@') || !t.contains('.')) {
                        return 'Correo no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Rol asignado',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'doctor', child: Text('Doctor')),
                      DropdownMenuItem(
                          value: 'paciente', child: Text('Paciente')),
                      DropdownMenuItem(
                          value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (v) =>
                        setState(() => _rolSeleccionado = v ?? 'doctor'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _violeta,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _guardando ? null : _crearInvitacion,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_outlined,
                              color: Colors.white),
                      label: const Text('Crear invitación',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---- Lista de invitaciones pendientes ----
          const Text('Invitaciones pendientes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _invitesRef.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: _violeta),
                  ),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inbox_outlined, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      Text('No hay invitaciones pendientes.',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final emailLower = doc.id;
                  final rol = (doc.data()['rol'] as String?) ?? '—';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8E5FF),
                        child: Icon(_iconForRol(rol), color: _violeta),
                      ),
                      title: Text(emailLower,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Rol: ${_labelRol(rol)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _eliminarInvitacion(emailLower),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconForRol(String rol) {
    switch (rol) {
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _labelRol(String rol) {
    switch (rol) {
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Administrador';
      case 'paciente':
        return 'Paciente';
      default:
        return rol;
    }
  }
}