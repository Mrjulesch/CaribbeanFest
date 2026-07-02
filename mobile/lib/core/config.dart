/// Configuración de entorno. La URL base se puede sobreescribir al compilar:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String get restBase => '$apiBaseUrl/api';

  /// Namespace de Socket.IO para el scoring en vivo.
  static String get liveSocketUrl => '$apiBaseUrl/live';

  // Cloudinary (subida directa del PDF de consentimiento). Son valores PÚBLICOS,
  // seguros de exponer. Se pasan al compilar: --dart-define=CLOUDINARY_CLOUD_NAME=...
  static const String cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
  static const String cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  static bool get cloudinaryReady =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
}
