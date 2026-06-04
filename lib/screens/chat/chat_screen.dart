import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Pantalla de chat 1-a-1 entre doctor y paciente.
///
/// La conversación vive en `/chats/{chatId}` (con `participants: [a, b]`)
/// y los mensajes en `/chats/{chatId}/messages`. El `chatId` se construye
/// ordenando los dos UIDs y juntándolos con "_" para que el chat sea el
/// mismo lo abra primero quien sea.
///
/// Importante: el documento del chat se crea ANTES de iniciar el stream
/// de mensajes, porque las reglas de Firestore validan los messages contra
/// el campo `participants` del doc padre. Si el doc no existiera, la regla
/// fallaría con permission-denied.
class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _myUid;
  String _chatId = '';
  bool _sending = false;

  /// Future que se completa cuando el documento del chat existe en Firestore.
  /// Se inicializa en initState y se usa con FutureBuilder en el build para
  /// retrasar la suscripción al stream de mensajes hasta que las reglas
  /// puedan validarlo correctamente.
  late Future<void> _chatReady;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    if (_myUid != null) {
      _chatId = _buildChatId(_myUid!, widget.otherUserId);
      _chatReady = _ensureChatExists();
    } else {
      _chatReady = Future.error('No hay sesión activa');
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _buildChatId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  Future<void> _ensureChatExists() async {
    if (_myUid == null) return;
    final docRef = _db.collection('chats').doc(_chatId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'participants': [_myUid, widget.otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });
    }
  }

  /// Crea una notificación al destinatario cuando le mandamos un mensaje.
  /// Esto permite que aparezca el badge en su campanita.
  Future<void> _notificarDestinatario(String texto) async {
    if (_myUid == null) return;
    try {
      // Obtener el nombre de quien envía (para el título de la notif)
      final meDoc = await _db.collection('users').doc(_myUid).get();
      final meData = meDoc.data() ?? {};
      final miNombre = (meData['nombre'] as String?) ?? 'Alguien';
      final miRol = (meData['rol'] as String?) ?? '';
      final prefijo = miRol == 'doctor' ? 'Dr(a). ' : '';

      await _db
          .collection('users')
          .doc(widget.otherUserId)
          .collection('notificaciones')
          .add({
        'title': 'Nuevo mensaje',
        'body': '$prefijo$miNombre: $texto',
        'type': 'CHAT_MESSAGE',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'chatId': _chatId,
        'fromUid': _myUid,
      });
    } catch (e) {
      // No bloqueamos el envío del mensaje si la notif falla; solo logueamos.
      debugPrint('No se pudo crear notif para destinatario: $e');
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _myUid == null || _sending) return;

    setState(() => _sending = true);
    try {
      // 1. Asegura que el chat existe (idempotente)
      await _ensureChatExists();

      // 2. Escribe el mensaje + actualiza el chat
      final batch = _db.batch();
      final chatRef = _db.collection('chats').doc(_chatId);
      final msgRef = chatRef.collection('messages').doc();

      batch.set(msgRef, {
        'senderId': _myUid,
        'text': texto,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(chatRef, {
        'lastMessage': texto,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      // 3. Notifica al destinatario (no bloqueante)
      // ignore: unawaited_futures
      _notificarDestinatario(texto);

      _msgCtrl.clear();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo enviar el mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión.')),
      );
    }

    final photoUrl = widget.otherUserPhotoUrl ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8E5FF),
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF6B5DE8))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _chatReady,
        builder: (context, readySnap) {
          if (readySnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (readySnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo abrir la conversación.\n${readySnap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db
                      .collection('chats')
                      .doc(_chatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No se pudo cargar la conversación.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Aún no hay mensajes.\nEnvía el primero.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        final senderId = (data['senderId'] as String?) ?? '';
                        final text = (data['text'] as String?) ?? '';
                        final ts = data['createdAt'];
                        final dt = ts is Timestamp ? ts.toDate() : null;
                        final isMine = senderId == _myUid;
                        return _MessageBubble(
                          text: text,
                          isMine: isMine,
                          timeLabel: dt == null
                              ? ''
                              : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje…',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _enviarMensaje(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFF6B5DE8),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _sending ? null : _enviarMensaje,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final String timeLabel;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF6B5DE8) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: isMine
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeLabel,
              style: TextStyle(
                color: isMine ? Colors.white70 : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}