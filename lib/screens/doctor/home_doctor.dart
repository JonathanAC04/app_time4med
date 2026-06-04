import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/catalogos.dart';
import '../../services/firestore_service.dart';
import 'paciente_doctor_detail.dart';
import '../chat/chat_screen.dart';

class HomeDoctor extends StatefulWidget {
  const HomeDoctor({Key? key}) : super(key: key);

  @override
  State<HomeDoctor> createState() => _HomeDoctorState();
}

class _HomeDoctorState extends State<HomeDoctor> {
  final String? _doctorId = FirebaseAuth.instance.currentUser?.uid;
  final FirestoreService _service = FirestoreService();
  int _selectedIndex = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _tituloDe(int i) {
    switch (i) {
      case 0: return 'Panel Médico';
      case 1: return 'Mis Pacientes';
      case 2: return 'Mensajes';
      case 3: return 'Mi Perfil';
      default: return 'Panel Médico';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver el panel.')),
      );
    }

    final pages = [
      _DoctorHomeTab(
        doctorId: _doctorId!,
        onGoToPatients: () => setState(() => _selectedIndex = 1),
        onGoToMessages: () => setState(() => _selectedIndex = 2),
      ),
      _DoctorPatientsTab(doctorId: _doctorId!),
      _DoctorMessagesTab(doctorId: _doctorId!),
      _DoctorProfileTab(doctorId: _doctorId!, onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _tituloDe(_selectedIndex),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Campana de notificaciones con badge (en lugar del tab "Alertas")
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.getUserNotificationsStream(_doctorId!),
            builder: (context, snap) {
              final all = snap.data?.docs ?? [];
              final unread = all.where((d) => (d.data()['read'] as bool?) != true).length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notificaciones',
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.black87),
                    onPressed: () => _abrirNotificaciones(context),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF6B5DE8),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Pacientes'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  void _abrirNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificacionesSheet(doctorId: _doctorId!),
    );
  }
}

// =====================================================================
// TAB 1: INICIO
// =====================================================================
class _DoctorHomeTab extends StatelessWidget {
  final String doctorId;
  final VoidCallback onGoToPatients;
  final VoidCallback onGoToMessages;

  const _DoctorHomeTab({
    required this.doctorId,
    required this.onGoToPatients,
    required this.onGoToMessages,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamDoctorPatients(doctorId),
      builder: (context, patientsSnap) {
        final patients = patientsSnap.data?.docs ?? [];

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.getUserStream(doctorId),
          builder: (context, userSnap) {
            final me = userSnap.data?.data() ?? {};
            final nombre = (me['nombre'] as String?) ?? 'Doctor';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Saludo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B5DE8), Color(0xFF4A3FBB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Hola,",
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        "Dr(a). $nombre",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Gestiona recetas, pacientes y mensajes en tiempo real.",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Pacientes',
                        value: patients.length.toString(),
                        icon: Icons.people_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Activos',
                        value: patients
                            .where((d) => (d.data()['doctorId'] as String?) == doctorId)
                            .length
                            .toString(),
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Acciones rápidas
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.people_alt_outlined,
                        label: 'Mis pacientes',
                        onTap: onGoToPatients,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.chat_bubble_outline,
                        label: 'Mensajes',
                        onTap: onGoToMessages,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Pacientes recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (patients.isEmpty)
                  const _EmptyCard(message: 'No hay pacientes asignados todavía.')
                else
                  ...patients.take(5).map((doc) {
                    final data = doc.data();
                    final nombrePac = (data['nombre'] as String?) ?? 'Paciente';
                    final fotoUrl = (data['fotoPerfilUrl'] as String?) ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8E5FF),
                          backgroundImage:
                              fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                          child: fotoUrl.isEmpty
                              ? const Icon(Icons.person, color: Color(0xFF6B5DE8))
                              : null,
                        ),
                        title: Text(nombrePac),
                        subtitle: Text((data['email'] as String?) ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PacienteDoctorDetail(
                              doctorId: doctorId,
                              patientId: doc.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}

// =====================================================================
// TAB 2: PACIENTES (igual que antes, con pequeño refinamiento)
// =====================================================================
class _DoctorPatientsTab extends StatelessWidget {
  final String doctorId;

  const _DoctorPatientsTab({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamDoctorPatients(doctorId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final patients = snap.data!.docs;
        if (patients.isEmpty) {
          return const _EmptyCard(
              message: 'Todavía no tienes pacientes asignados.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = patients[i];
            final data = doc.data();
            final nombre = (data['nombre'] as String?) ?? 'Paciente';
            final email = (data['email'] as String?) ?? '';
            final fotoUrl = (data['fotoPerfilUrl'] as String?) ?? '';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8E5FF),
                  backgroundImage:
                      fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                  child: fotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF6B5DE8))
                      : null,
                ),
                title: Text(nombre),
                subtitle: Text(email),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Chatear',
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF6B5DE8)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: doc.id,
                            otherUserName: nombre,
                            otherUserPhotoUrl: fotoUrl,
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PacienteDoctorDetail(
                      doctorId: doctorId,
                      patientId: doc.id,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =====================================================================
// TAB 3: MENSAJES (lista de chats con pacientes asignados)
// =====================================================================
class _DoctorMessagesTab extends StatelessWidget {
  final String doctorId;
  const _DoctorMessagesTab({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamDoctorPatients(doctorId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final patients = snap.data!.docs;
        if (patients.isEmpty) {
          return const _EmptyCard(
              message: 'Todavía no tienes pacientes con quien conversar.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = patients[i];
            final data = doc.data();
            final nombre = (data['nombre'] as String?) ?? 'Paciente';
            final fotoUrl = (data['fotoPerfilUrl'] as String?) ?? '';
            final chatId = _buildChatId(doctorId, doc.id);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .snapshots(),
                builder: (context, chatSnap) {
                  final chat = chatSnap.data?.data();
                  final last = (chat?['lastMessage'] as String?) ?? '';
                  return ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8E5FF),
                      backgroundImage:
                          fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                      child: fotoUrl.isEmpty
                          ? const Icon(Icons.person, color: Color(0xFF6B5DE8))
                          : null,
                    ),
                    title: Text(nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      last.isEmpty ? 'Sin mensajes aún' : last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color:
                              last.isEmpty ? Colors.grey : Colors.black54),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: doc.id,
                          otherUserName: nombre,
                          otherUserPhotoUrl: fotoUrl,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _buildChatId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }
}

// =====================================================================
// TAB 4: PERFIL (con autocomplete de especialidad)
// =====================================================================
class _DoctorProfileTab extends StatefulWidget {
  final String doctorId;
  final VoidCallback onLogout;

  const _DoctorProfileTab({
    required this.doctorId,
    required this.onLogout,
  });

  @override
  State<_DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<_DoctorProfileTab> {
  final FirestoreService _service = FirestoreService();

  Future<void> _showEditProfileDialog(Map<String, dynamic> currentData) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl =
        TextEditingController(text: (currentData['nombre'] as String?) ?? '');
    final telefonoCtrl =
        TextEditingController(text: (currentData['telefono'] as String?) ?? '');
    final fotoCtrl =
        TextEditingController(text: (currentData['fotoUrl'] as String?) ?? '');
    final cedulaCtrl =
        TextEditingController(text: (currentData['cedula'] as String?) ?? '');
    String especialidad = (currentData['especialidad'] as String?) ?? '';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar perfil'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  // 👇 AUTOCOMPLETE de especialidad
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: especialidad),
                    optionsBuilder: (TextEditingValue val) {
                      if (val.text.isEmpty) {
                        return Catalogos.especialidades;
                      }
                      final q = val.text.toLowerCase();
                      return Catalogos.especialidades
                          .where((e) => e.toLowerCase().contains(q));
                    },
                    onSelected: (sel) {
                      especialidad = sel;
                    },
                    fieldViewBuilder:
                        (context, ctrl, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: ctrl,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        onChanged: (v) => especialidad = v,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: cedulaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cédula profesional',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: fotoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL de foto (opcional)',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _service.updateUserData(
                          widget.doctorId,
                          {
                            'nombre': nombreCtrl.text.trim(),
                            'especialidad': especialidad.trim(),
                            'cedula': cedulaCtrl.text.trim(),
                            'telefono': telefonoCtrl.text.trim(),
                            'fotoUrl': fotoCtrl.text.trim(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Perfil actualizado correctamente.'),
                            backgroundColor: Color(0xFF6B5DE8),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo actualizar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.getUserStream(widget.doctorId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final nombre = (data['nombre'] as String?) ?? 'Doctor';
        final email = (data['email'] as String?) ?? '';
        final especialidad = (data['especialidad'] as String?) ?? '';
        final telefono = (data['telefono'] as String?) ?? '';
        final cedula = (data['cedula'] as String?) ?? '';
        final fotoUrl = (data['fotoUrl'] as String?) ?? '';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header con foto y nombre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE8E5FF),
                    backgroundImage: fotoUrl.trim().isNotEmpty
                        ? NetworkImage(fotoUrl.trim())
                        : null,
                    child: fotoUrl.trim().isEmpty
                        ? const Icon(Icons.person,
                            size: 56, color: Color(0xFF6B5DE8))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dr(a). $nombre',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (especialidad.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E5FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        especialidad,
                        style: const TextStyle(
                          color: Color(0xFF6B5DE8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(data),
                      icon: const Icon(Icons.edit, color: Color(0xFF6B5DE8)),
                      label: const Text('Editar perfil',
                          style: TextStyle(color: Color(0xFF6B5DE8))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6B5DE8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Datos
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: email.isEmpty ? '—' : email),
                  const Divider(height: 1),
                  _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: telefono.isEmpty ? '—' : telefono),
                  const Divider(height: 1),
                  _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Cédula',
                      value: cedula.isEmpty ? '—' : cedula),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Logout
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Cerrar sesión',
                    style: TextStyle(color: Colors.redAccent)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =====================================================================
// MODAL: Notificaciones (se abre desde la campanita del AppBar)
// =====================================================================
class _NotificacionesSheet extends StatelessWidget {
  final String doctorId;
  const _NotificacionesSheet({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Notificaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.getUserNotificationsStream(doctorId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No tienes notificaciones aún.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final n = doc.data();
                      final title = (n['title'] as String?) ?? '';
                      final body = (n['body'] as String?) ?? '';
                      final read = (n['read'] as bool?) ?? false;
                      return Container(
                        decoration: BoxDecoration(
                          color: read ? Colors.grey.shade100 : const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: read ? Colors.grey.shade200 : const Color(0xFFE8E5FF),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE8E5FF),
                            child: Icon(
                              read
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: const Color(0xFF6B5DE8),
                            ),
                          ),
                          title: Text(title,
                              style: TextStyle(
                                fontWeight:
                                    read ? FontWeight.w500 : FontWeight.bold,
                              )),
                          subtitle: Text(body),
                          onTap: read
                              ? null
                              : () => service.markUserNotificationAsRead(
                                    uid: doctorId,
                                    notificationId: doc.id,
                                  ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Widgets auxiliares
// =====================================================================
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6B5DE8)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6B5DE8), size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B5DE8)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}