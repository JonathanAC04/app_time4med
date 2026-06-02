import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio para subir imágenes a Cloudinary usando upload preset unsigned.
/// No requiere backend ni Cloud Functions.
class CloudinaryService {
  // ⚠️ REEMPLAZA estos dos valores con los tuyos del dashboard de Cloudinary.
  static const String _cloudName = 'dbxqyphup';     // p. ej. 'dxyzabc123'
  static const String _uploadPreset = 'time4med_unsigned'; // p. ej. 'time4med_unsigned'

  /// Sube una imagen y devuelve la URL pública (`secure_url`).
  /// Retorna `null` si falla.
  /// 
  /// [folder] es opcional, sirve para organizar imágenes en carpetas dentro
  /// de Cloudinary (ej: "perfiles_pacientes", "perfiles_doctores").
  static Future<String?> uploadImage(
    List<int> bytes, {
    String? folder,
    String? publicId,
  }) async {
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }
    if (publicId != null && publicId.isNotEmpty) {
      request.fields['public_id'] = publicId;
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
}