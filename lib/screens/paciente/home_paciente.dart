import 'package:flutter/material.dart';

class HomePaciente extends StatefulWidget {
  @override
  _HomePacienteState createState() => _HomePacienteState();
}

class _HomePacienteState extends State<HomePaciente> {
  int _selectedIndex = 0; // Para la barra de navegación inferior

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(),
            SizedBox(height: 25),
            _buildProximasTomasHeader(),
            SizedBox(height: 15),
            // Lista de Medicamentos
            _buildMedicationCard("08:00", "Atorvastatina", "1 tableta (20mg)", "TOMADO", Colors.teal),
            _buildMedicationCard("10:00", "Metformina", "1 tableta (850mg)", "POSPUESTO", Colors.orange),
            _buildMedicationCard("14:00", "Vitamina D3", "1 cápsula (2000 UI)", "PENDIENTE", Colors.indigoAccent),
            _buildMedicationCard("21:00", "Lisinopril", "1 tableta (10mg)", "PENDIENTE", Colors.indigoAccent),
            SizedBox(height: 20),
            _buildConsejoDelDia(),
            SizedBox(height: 60), // Espacio para que no lo tape el botón flotante
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Color(0xFF6B5DE8), // Morado del diseño
        child: Icon(Icons.add, color: Colors.white, size: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- WIDGETS PERSONALIZADOS ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(Icons.monitor_heart, color: Colors.white, size: 20),
        ),
      ),
      title: Column(
        children: [
          Text("HOY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text("25/02/2026", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(icon: Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
            Positioned(top: 12, right: 12, child: CircleAvatar(radius: 4, backgroundColor: Colors.red)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15.0, left: 5),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.white),
          ),
        )
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF3F0FF), // Morado clarito
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progreso de hoy", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text("25%", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          SizedBox(height: 5),
          Text("1 de 4 dosis", style: TextStyle(color: Color(0xFF6B5DE8), fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.25,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: Color(0xFF6B5DE8),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProximasTomasHeader() {
    return Row(
      children: [
        Text("Próximas Tomas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(width: 10),
        CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade200, child: Text("4", style: TextStyle(fontSize: 12, color: Colors.black54))),
        Spacer(),
        Text("Ver todo", style: TextStyle(color: Color(0xFF6B5DE8), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMedicationCard(String time, String title, String subtitle, String status, Color color) {
    IconData statusIcon;
    if (status == "TOMADO") statusIcon = Icons.check_circle_outline;
    else if (status == "POSPUESTO") statusIcon = Icons.error_outline;
    else statusIcon = Icons.radio_button_unchecked;

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Línea de color a la izquierda
            Container(width: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    // Hora
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    SizedBox(width: 20),
                    // Detalles de la medicina
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.link, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          )
                        ],
                      ),
                    ),
                    // Estado (Tomado, pendiente, etc)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: color, size: 30),
                        SizedBox(height: 4),
                        Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsejoDelDia() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF6B5DE8)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Consejo del día", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 5),
                Text(
                  "Recuerda tomar tu Metformina con los alimentos para reducir molestias estomacales.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: Color(0xFF6B5DE8),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Mi Día"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Agenda"),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Salud"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Ajustes"),
      ],
    );
  }
}