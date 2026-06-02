import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';   // ← NUEVO
import 'editar_paciente_view.dart';

class PerfilPaciente extends StatefulWidget {
  const PerfilPaciente({Key? key}) : super(key: key);

  @override
  _PerfilPacienteState createState() => _PerfilPacienteState();
}

class _PerfilPacienteState extends State<PerfilPaciente> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  void _showSnackBar(String message, {Color color = const Color(0xFF6B5DE8)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _seleccionarFotoGaleria() async {
  if (_uid == null) return;
  final image = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
  );
  if (image == null) return;

  if (mounted) _showSnackBar("📤 Subiendo foto...");

  final bytes = await image.readAsBytes();
  final url = await CloudinaryService.uploadImage(
    bytes,
    folder: 'perfiles_pacientes',
    publicId: _uid, // sobreescribe la foto anterior del mismo usuario
  );

  if (url == null) {
    if (mounted) {
      _showSnackBar("❌ Error al subir la foto. Intenta de nuevo.",
          color: Colors.red);
    }
    return;
  }

  await _firestoreService.updateUserData(_uid!, {'fotoPerfilUrl': url});
  if (mounted) _showSnackBar("✅ Foto de perfil actualizada.");
}

Future<void> _borrarFotoPerfil() async {
  if (_uid == null) return;
  await _firestoreService
      .updateUserData(_uid!, {'fotoPerfilUrl': FieldValue.delete()});
  if (mounted) _showSnackBar("🗑️ Foto de perfil eliminada.");
}


  void _abrirMenuFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF6B5DE8)),
              title: const Text("Elegir de la galería"),
              onTap: () async {
                Navigator.pop(ctx);
                await _seleccionarFotoGaleria();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFFF4C79)),
              title: const Text("Borrar foto de perfil"),
              onTap: () async {
                Navigator.pop(ctx);
                await _borrarFotoPerfil();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cerrar sesión", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _irAEditarPaciente() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditarPacienteView()));
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text("Inicia sesión para ver tu perfil.")));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getUserStream(_uid!),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final nombre = (data['nombre'] as String?) ?? 'Paciente';
        final sexo = (data['sexo'] as String?) ?? 'No definido';
        final tipoSangre = (data['tipoSangre'] as String?) ?? 'No definido';
        final peso = data['peso']?.toString() ?? 'N/D';
        final fechaNac = (data['fechaNacimiento'] as String?) ?? 'N/D';
        final esAsignado = data['doctorId'] != null || data['medico'] != null;
        final fotoUrl = (data['fotoPerfilUrl'] as String?) ?? '';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text("Perfil del Usuario",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _abrirMenuFoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE8E5FF),
                        backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                        child: fotoUrl.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF6B5DE8), size: 50)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B5DE8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (esAsignado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text("ASIGNADO",
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("DATOS DEL PACIENTE",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextButton(onPressed: _irAEditarPaciente, child: const Text("Ver Todo")),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDatoCard(Icons.calendar_month, "NACIMIENTO", fechaNac),
                _buildDatoCard(Icons.person_outline, "GÉNERO", sexo),
                _buildDatoCard(Icons.water_drop_outlined, "SANGRE", tipoSangre),
                _buildDatoCard(Icons.scale_outlined, "PESO", "$peso kg"),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _irAEditarPaciente,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text("Editar Información Personal"),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Cerrar Sesión",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onPressed: _confirmarCerrarSesion,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatoCard(IconData icon, String titulo, String valor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B5DE8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
