import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApiConfig {
  static String _envUrl = '';

  /// Loads API_URL from .env file if available
  static Future<void> init() async {
    try {
      final envString = await rootBundle.loadString('.env');
      for (final line in envString.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final parts = trimmed.split('=');
        if (parts.length >= 2 && parts[0].trim() == 'API_URL') {
          _envUrl = parts.sublist(1).join('=').trim();
          break;
        }
      }
    } catch (_) {}
  }

  /// Base URL of the backend API.
  /// Defaults to local development (http://localhost:3000), read from .env / --dart-define=API_URL=...
  static String get baseUrl {
    String url = _envUrl.isNotEmpty
        ? _envUrl
        : const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://localhost:3000',
          );

    // On Android Emulator (non-web), route localhost to 10.0.2.2 so it can reach host machine
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        url.contains('localhost')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  /// Resolves any relative or localhost URL into the active backend URL
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://localhost:3000')) {
      return trimmed.replaceFirst('http://localhost:3000', baseUrl);
    }
    if (trimmed.startsWith('http://10.0.2.2:3000')) {
      return trimmed.replaceFirst('http://10.0.2.2:3000', baseUrl);
    }
    if (trimmed.startsWith('http://127.0.0.1:3000')) {
      return trimmed.replaceFirst('http://127.0.0.1:3000', baseUrl);
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return trimmed;
  }
}
