import 'package:flutter/material.dart';

class NotificacionesPaciente extends StatefulWidget {
  const NotificacionesPaciente({Key? key}) : super(key: key);

  @override
  _NotificacionesPacienteState createState() =>
      _NotificacionesPacienteState();
}

class _NotificacionesPacienteState extends State<NotificacionesPaciente> {
  final List<_NotificacionItem> _notificaciones = [
    _NotificacionItem(
      icono: Icons.medication_outlined,
      titulo: "Hora de tomar tu medicamento",
      descripcion: "Es hora de tomar tu dosis de Atorvastatina (20mg).",
      tiempo: "Hace 5 minutos",
      leida: false,
      color: const Color(0xFF6B5DE8),
    ),
    _NotificacionItem(
      icono: Icons.check_circle_outline,
      titulo: "Dosis registrada",
      descripcion: "Has marcado Metformina como tomada. ¡Buen trabajo!",
      tiempo: "Hace 2 horas",
      leida: false,
      color: Colors.green,
    ),
    _NotificacionItem(
      icono: Icons.calendar_today_outlined,
      titulo: "Recordatorio de cita",
      descripcion: "Tienes una cita con tu médico mañana a las 10:00 AM.",
      tiempo: "Hace 5 horas",
      leida: true,
      color: Colors.orange,
    ),
    _NotificacionItem(
      icono: Icons.warning_amber_outlined,
      titulo: "Medicamento próximo a vencer",
      descripcion: "Tu tratamiento de Ibuprofeno 600 vence en 3 días.",
      tiempo: "Ayer",
      leida: true,
      color: Colors.redAccent,
    ),
    _NotificacionItem(
      icono: Icons.info_outline,
      titulo: "Actualización de receta",
      descripcion: "Tu médico ha actualizado tu receta médica. Revísala.",
      tiempo: "Hace 2 días",
      leida: true,
      color: Colors.blueAccent,
    ),
  ];

  void _marcarTodasLeidas() {
    setState(() {
      for (final n in _notificaciones) {
        n.leida = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = _notificaciones.where((n) => !n.leida).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notificaciones",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            if (noLeidas > 0)
              Text(
                "$noLeidas sin leer",
                style: const TextStyle(
                    color: Color(0xFF6B5DE8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
        actions: [
          if (noLeidas > 0)
            TextButton(
              onPressed: _marcarTodasLeidas,
              child: const Text(
                "Marcar todas",
                style: TextStyle(
                    color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _notificaciones.isEmpty
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
              itemCount: _notificaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = _notificaciones[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => notif.leida = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: notif.leida
                          ? Colors.white
                          : const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: notif.leida
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
                            color: notif.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(notif.icono,
                              color: notif.color, size: 24),
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
                                      notif.titulo,
                                      style: TextStyle(
                                        fontWeight: notif.leida
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!notif.leida)
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
                                notif.descripcion,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.tiempo,
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
    );
  }
}

class _NotificacionItem {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String tiempo;
  bool leida;
  final Color color;

  _NotificacionItem({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.tiempo,
    required this.leida,
    required this.color,
  });
}
