import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class NotificacionesPaciente extends StatefulWidget {
  const NotificacionesPaciente({Key? key}) : super(key: key);

  @override
  _NotificacionesPacienteState createState() =>
      _NotificacionesPacienteState();
}

class _NotificacionesPacienteState extends State<NotificacionesPaciente> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _marcarTodasLeidas(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (_uid == null) return;
    for (final doc in docs) {
      final data = doc.data();
      if ((data['read'] as bool?) == true) continue;
      await _firestoreService.markUserNotificationAsRead(
        uid: _uid!,
        notificationId: doc.id,
      );
    }
  }

  String _formatTiempo(Timestamp? ts) {
    if (ts == null) return "Ahora";
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return "Hace unos segundos";
    if (diff.inMinutes < 60) return "Hace ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Hace ${diff.inHours} h";
    return "Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}";
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'DOCTOR_MEDICATION_ASSIGNED':
      case 'MEDICATION_STATUS_ALERT':
        return Icons.medication_outlined;
      case 'DOCTOR_MEDICATION_UPDATED':
        return Icons.edit_note_outlined;
      case 'DOCTOR_MEDICATION_DELETED':
        return Icons.delete_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'DOCTOR_MEDICATION_ASSIGNED':
        return const Color(0xFF6B5DE8);
      case 'DOCTOR_MEDICATION_UPDATED':
        return Colors.blueAccent;
      case 'DOCTOR_MEDICATION_DELETED':
        return Colors.redAccent;
      case 'MEDICATION_STATUS_ALERT':
        return Colors.orange;
      default:
        return const Color(0xFF6B5DE8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text("Inicia sesión para ver tus notificaciones.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notificaciones",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getUserNotificationsStream(_uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5DE8)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final noLeidas =
              docs.where((d) => (d.data()['read'] as bool?) != true).length;

          return Column(
            children: [
              if (noLeidas > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _marcarTodasLeidas(docs),
                    child: const Text(
                      "Marcar todas",
                      style: TextStyle(
                          color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 15),
                            Text(
                              "No tienes notificaciones",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = docs[index].data();
                          final leida = (notif['read'] as bool?) ?? false;
                          final tipo = (notif['type'] as String?) ?? '';
                          final color = _colorForType(tipo);
                          return GestureDetector(
                            onTap: () => _firestoreService.markUserNotificationAsRead(
                              uid: _uid!,
                              notificationId: docs[index].id,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: leida
                                    ? Colors.white
                                    : const Color(0xFFF3F0FF),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: leida
                                      ? Colors.grey.shade200
                                      : const Color(0xFF6B5DE8).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_iconForType(tipo),
                                        color: color, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (notif['title'] as String?) ??
                                                    'Notificación',
                                                style: TextStyle(
                                                  fontWeight: leida
                                                      ? FontWeight.w500
                                                      : FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (!leida)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF6B5DE8),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (notif['body'] as String?) ?? '',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTiempo(
                                              notif['createdAt'] as Timestamp?),
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
    );
  }
}
