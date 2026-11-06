class ApiConfig {
  /// Base URL of the live deployed backend on Render
  static const String baseUrl = 'https://games-24-final.onrender.com';

  /// Resolves any relative or localhost URL into the live cloud backend URL
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

