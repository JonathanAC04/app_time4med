import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'paciente_doctor_detail.dart';

class HomeDoctor extends StatefulWidget {
  const HomeDoctor({Key? key}) : super(key: key);

  @override
  State<HomeDoctor> createState() => _HomeDoctorState();
}

class _HomeDoctorState extends State<HomeDoctor> {
  final String? _doctorId = FirebaseAuth.instance.currentUser?.uid;
  int _selectedIndex = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
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
      ),
      _DoctorPatientsTab(doctorId: _doctorId!),
      _DoctorNotificationsTab(doctorId: _doctorId!),
      _DoctorProfileTab(doctorId: _doctorId!, onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Panel Médico',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          )
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
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _DoctorHomeTab extends StatelessWidget {
  final String doctorId;
  final VoidCallback onGoToPatients;

  const _DoctorHomeTab({
    required this.doctorId,
    required this.onGoToPatients,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamDoctorPatients(doctorId),
      builder: (context, patientsSnap) {
        final patients = patientsSnap.data?.docs ?? [];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.getUserNotificationsStream(doctorId),
          builder: (context, notiSnap) {
            final notis = notiSnap.data?.docs ?? [];
            final unread =
                notis.where((d) => (d.data()['read'] as bool?) != true).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hola, Doctor(a)",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      SizedBox(height: 4),
                      Text(
                        "Gestiona recetas, pacientes y alertas en tiempo real.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                        title: 'Alertas',
                        value: unread.toString(),
                        icon: Icons.notifications_active_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onGoToPatients,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text('Ver mis pacientes',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5DE8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pacientes recientes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (patients.isEmpty)
                  const _EmptyCard(
                      message: 'No hay pacientes asignados a este doctor.')
                else
                  ...patients.take(5).map((doc) {
                    final data = doc.data();
                    final nombre = (data['nombre'] as String?) ?? 'Paciente';
                    final peso = data['peso']?.toString() ?? 'N/D';
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8E5FF),
                        child: Icon(Icons.person, color: Color(0xFF6B5DE8)),
                      ),
                      title: Text(nombre),
                      subtitle: Text('Peso: $peso kg'),
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

class _DoctorPatientsTab extends StatelessWidget {
  final String doctorId;

  const _DoctorPatientsTab({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamDoctorPatients(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B5DE8)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyCard(
              message: 'No tienes pacientes asignados actualmente.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final nombre = (data['nombre'] as String?) ?? 'Paciente';
            final sexo = (data['sexo'] as String?) ?? 'N/D';
            return Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8E5FF),
                  child: Icon(Icons.person, color: Color(0xFF6B5DE8)),
                ),
                title: Text(nombre),
                subtitle: Text('Sexo: $sexo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PacienteDoctorDetail(
                      doctorId: doctorId,
                      patientId: docs[index].id,
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

class _DoctorNotificationsTab extends StatelessWidget {
  final String doctorId;

  const _DoctorNotificationsTab({required this.doctorId});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'Ahora';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Hace unos segundos';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.getUserNotificationsStream(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5DE8)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyCard(
              message: 'Sin notificaciones por el momento.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final read = (data['read'] as bool?) ?? false;
            return InkWell(
              onTap: () => service.markUserNotificationAsRead(
                uid: doctorId,
                notificationId: docs[index].id,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: read ? Colors.white : const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notification_important_outlined,
                        color: Color(0xFF6B5DE8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['title'] as String?) ?? 'Notificación',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text((data['body'] as String?) ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(data['createdAt'] as Timestamp?),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
    final nombreCtrl = TextEditingController(text: (currentData['nombre'] as String?) ?? '');
    final especialidadCtrl = TextEditingController(text: (currentData['especialidad'] as String?) ?? '');
    final telefonoCtrl = TextEditingController(text: (currentData['telefono'] as String?) ?? '');
    final fotoCtrl = TextEditingController(text: (currentData['fotoUrl'] as String?) ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar perfil'),
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
                    controller: especialidadCtrl,
                    decoration: const InputDecoration(labelText: 'Especialidad'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: fotoCtrl,
                    decoration: const InputDecoration(labelText: 'URL de foto (opcional)'),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8)),
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
                            'especialidad': especialidadCtrl.text.trim(),
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
                            content: Text('No se pudo actualizar el perfil: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar', style: TextStyle(color: Colors.white)),
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
        final fotoUrl = (data['fotoUrl'] as String?) ?? '';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFE8E5FF),
                    backgroundImage: fotoUrl.trim().isNotEmpty ? NetworkImage(fotoUrl.trim()) : null,
                    child: fotoUrl.trim().isNotEmpty
                        ? null
                        : const Icon(Icons.person, color: Color(0xFF6B5DE8), size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(nombre,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  if (especialidad.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Especialidad: $especialidad', style: const TextStyle(color: Colors.grey)),
                  ],
                  if (telefono.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Teléfono: $telefono', style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B5DE8)),
              onPressed: () => _showEditProfileDialog(data),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Editar perfil', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6B5DE8)),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey)),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
