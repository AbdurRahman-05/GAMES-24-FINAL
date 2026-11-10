import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  /// Base URL of the backend API.
  /// Priority:
  /// 1. .env file: API_URL=http://localhost:3000
  /// 2. CLI flag: --dart-define=API_URL=...
  /// 3. Default: http://localhost:3000
  static String get baseUrl {
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:3000',
    );
  }

  /// Resolves any relative or localhost URL into the active backend URL
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://localhost:3000') ||
        trimmed.startsWith('http://10.0.2.2:3000') ||
        trimmed.startsWith('http://127.0.0.1:3000')) {
      try {
        final uri = Uri.parse(trimmed);
        return '$baseUrl${uri.path}';
      } catch (_) {
        return trimmed;
      }
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return trimmed;
  }
}
