class ApiConfig {
  /// Base URL of the backend API.
  /// Hardcoded to live Render deployment, with optional build-time override via --dart-define=API_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://games-24-final.onrender.com',
  );

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
