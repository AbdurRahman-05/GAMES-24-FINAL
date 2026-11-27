import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../api_config.dart';

/// Result of an API call: either decoded JSON data or a human readable error message.
class ApiResult {
  final int statusCode;
  final dynamic data;
  final String? error;

  const ApiResult({required this.statusCode, this.data, this.error});

  bool get ok => error == null && statusCode >= 200 && statusCode < 300;

  /// Convenience accessor for JSON object responses.
  Map<String, dynamic> get map =>
      data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{};

  /// The server's message (NestJS puts it in `message`, sometimes as a list) or the error text.
  String get message {
    if (error != null) return error!;
    final m = map['message'];
    if (m is List && m.isNotEmpty) return m.first.toString();
    if (m != null) return m.toString();
    return ok ? 'Done' : 'Something went wrong';
  }
}

/// Small wrapper around `http` used by the managers:
/// * one place for timeouts (the free Render backend can take ~30-50s to wake up),
/// * GETs are retried once on network errors (cold start), mutations are never retried,
/// * non-2xx responses are returned with the server's error message instead of being swallowed.
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 25);
  static const Duration _coldStartTimeout = Duration(seconds: 45);

  static Uri uri(String path, [Map<String, String?>? query]) {
    final clean = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) clean[k] = v;
    });
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    return clean.isEmpty ? base : base.replace(queryParameters: clean);
  }

  static Future<ApiResult> get(String path, {Map<String, String?>? query}) async {
    final target = uri(path, query);
    try {
      return _decode(await http.get(target).timeout(_timeout));
    } on TimeoutException {
      // Most likely a cold start: give the server one longer attempt.
      return _attempt(() => http.get(target).timeout(_coldStartTimeout));
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return _attempt(() => http.get(target).timeout(_coldStartTimeout));
    }
  }

  static Future<ApiResult> post(String path, {Object? body}) =>
      _attempt(() => http
          .post(uri(path), headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body ?? {}))
          .timeout(_coldStartTimeout));

  static Future<ApiResult> patch(String path, {Object? body}) =>
      _attempt(() => http
          .patch(uri(path), headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body ?? {}))
          .timeout(_coldStartTimeout));

  /// Uploads an image to the backend (`/upload/photo`) and returns its public URL, or null.
  /// Uses bytes so it works on Android, iOS and web alike.
  static Future<String?> uploadPhoto(List<int> bytes, String filename) async {
    try {
      final lower = filename.toLowerCase();
      final subtype = lower.endsWith('.png')
          ? 'png'
          : lower.endsWith('.webp')
              ? 'webp'
              : 'jpeg';
      final request = http.MultipartRequest('POST', uri('/upload/photo'))
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType('image', subtype),
        ));
      final streamed = await request.send().timeout(_coldStartTimeout);
      final res = await http.Response.fromStream(streamed);
      final result = _decode(res);
      final url = result.ok ? result.map['url']?.toString() : null;
      return (url != null && url.startsWith('http')) ? url : null;
    } catch (e) {
      debugPrint('Photo upload failed: $e');
      return null;
    }
  }

  static Future<ApiResult> _attempt(Future<http.Response> Function() send) async {
    try {
      return _decode(await send());
    } on TimeoutException {
      return const ApiResult(
        statusCode: 0,
        error: 'The server is taking too long to respond. Please try again.',
      );
    } catch (e) {
      debugPrint('ApiClient network error: $e');
      return const ApiResult(
        statusCode: 0,
        error: 'Unable to connect. Please check your internet connection.',
      );
    }
  }

  static ApiResult _decode(http.Response res) {
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = res.body;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ApiResult(statusCode: res.statusCode, data: data);
    }
    String msg = 'Request failed (${res.statusCode})';
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      msg = m is List && m.isNotEmpty ? m.first.toString() : m.toString();
    }
    return ApiResult(statusCode: res.statusCode, data: data, error: msg);
  }
}
