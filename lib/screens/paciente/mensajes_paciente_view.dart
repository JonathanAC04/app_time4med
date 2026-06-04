import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';

/// Pantalla simple para que el paciente vea la conversación con su doctor.
///
/// Como cada paciente tiene UN solo doctor asignado (campo `doctorId` en su
/// documento de `users`), aquí no hace falta una lista larga: si el paciente
/// tiene doctor asignado, mostramos su tarjeta y se va directo al ChatScreen.
class MensajesPacienteView extends StatefulWidget {
  const MensajesPacienteView({super.key});

  @override
  State<MensajesPacienteView> createState() => _MensajesPacienteViewState();
}

class _MensajesPacienteViewState extends State<MensajesPacienteView> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  String _buildChatId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mensajes',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(_uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final me = userSnap.data?.data() ?? {};
          final doctorId = (me['doctorId'] as String?) ?? '';

          if (doctorId.isEmpty) {
            return _EmptyState(
              title: 'Sin doctor asignado',
              message:
                  'Cuando un administrador te asigne un doctor podrás conversar con él aquí.',
              icon: Icons.medical_services_outlined,
            );
          }

          // Cargamos el doc del doctor para mostrar su info
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.collection('users').doc(doctorId).snapshots(),
            builder: (context, docSnap) {
              if (!docSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docData = docSnap.data?.data() ?? {};
              final nombre =
                  (docData['nombre'] as String?) ?? 'Doctor';
              final especialidad =
                  (docData['especialidad'] as String?) ?? '';
              final fotoUrl = (docData['fotoUrl'] as String?) ?? '';
              final chatId = _buildChatId(_uid!, doctorId);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E5FF)),
                    ),
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection('chats')
                          .doc(chatId)
                          .snapshots(),
                      builder: (context, chatSnap) {
                        final chat = chatSnap.data?.data();
                        final last = (chat?['lastMessage'] as String?) ?? '';
                        return ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFE8E5FF),
                            backgroundImage: fotoUrl.trim().isNotEmpty
                                ? NetworkImage(fotoUrl.trim())
                                : null,
                            child: fotoUrl.trim().isEmpty
                                ? const Icon(Icons.person,
                                    size: 32, color: Color(0xFF6B5DE8))
                                : null,
                          ),
                          title: Text(
                            'Dr(a). $nombre',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (especialidad.isNotEmpty)
                                Text(especialidad,
                                    style: const TextStyle(
                                        color: Color(0xFF6B5DE8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                last.isEmpty
                                    ? 'Toca para empezar a chatear'
                                    : last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: last.isEmpty
                                        ? Colors.grey
                                        : Colors.black54),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Color(0xFF6B5DE8)),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: doctorId,
                                otherUserName: 'Dr(a). $nombre',
                                otherUserPhotoUrl: fotoUrl,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF6B5DE8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tu doctor recibirá tus mensajes y podrá responderte. '
                            'En caso de urgencia médica llama al 911.',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const _EmptyState(
      {required this.title, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}