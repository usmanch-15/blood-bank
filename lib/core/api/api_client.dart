import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../errors/app_exceptions.dart';

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'CLOUDFLARE_API_URL',
    defaultValue: 'https://blood-connect-api.usman4009797.workers.dev',
  );
  static const _timeout = Duration(seconds: 20);
  static final instance = ApiClient();

  final http.Client _client;
  final Future<String?> Function() _idTokenProvider;

  ApiClient({
    http.Client? client,
    Future<String?> Function()? idTokenProvider,
  }) : _client = client ?? http.Client(),
       _idTokenProvider = idTokenProvider ?? _firebaseIdToken;

  static Future<String?> _firebaseIdToken() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AuthException('Please sign in to continue.');
    }
    return user.getIdToken();
  }

  Future<Map<String, dynamic>> call(
    String workflow, [
    Map<String, dynamic> data = const {},
  ]) async {
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9]*$').hasMatch(workflow)) {
      throw AppException('Invalid service request.', code: 'invalid-argument');
    }

    try {
      final token = await _idTokenProvider().timeout(_timeout);
      if (token == null || token.isEmpty) {
        throw AuthException('Please sign in to continue.');
      }

      final response = await _client
          .post(
            Uri.parse('$baseUrl/call/$workflow'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'data': data}),
          )
          .timeout(_timeout);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AppException(
          'The request service returned an invalid response.',
          code: 'internal',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        final code =
            error is Map ? '${error['code'] ?? 'internal'}' : 'internal';
        final message =
            error is Map
                ? '${error['message'] ?? 'The request could not be completed.'}'
                : 'The request could not be completed.';
        throw AppException(message, code: code);
      }

      final result = decoded['result'];
      if (result is! Map) {
        throw AppException(
          'The request service returned an invalid result.',
          code: 'internal',
        );
      }
      return Map<String, dynamic>.from(result);
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } on http.ClientException {
      throw NetworkException(
        'Could not connect to the request service. Check your connection.',
      );
    } on FormatException {
      throw AppException(
        'The request service returned an invalid response.',
        code: 'internal',
      );
    }
  }
}
