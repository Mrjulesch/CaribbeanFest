import 'package:dio/dio.dart';

import 'config.dart';

/// Sube archivos directo a Cloudinary con un "upload preset" sin firmar (unsigned).
/// No usa secretos: solo el cloud name y el preset, que son valores públicos.
class CloudinaryService {
  static bool get ready => AppConfig.cloudinaryReady;

  /// Sube un PDF (bytes) y devuelve la URL segura del archivo.
  static Future<String> uploadPdf(List<int> bytes, String filename) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'upload_preset': AppConfig.cloudinaryUploadPreset,
    });
    // 'auto' conserva el PDF tal cual y devuelve su URL de descarga.
    final res = await Dio().post(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/auto/upload',
      data: form,
    );
    return res.data['secure_url'] as String;
  }
}
