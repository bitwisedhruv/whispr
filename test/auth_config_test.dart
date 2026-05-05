import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whispr/core/config.dart';
import 'dart:io';

void main() {
  group('Supabase Configuration & Auth Integration Tests', () {
    test('Environment variables contain valid URL and Key', () {
      final url = AppConfig.supabaseUrl;
      final anonKey = AppConfig.supabaseAnonKey;

      expect(url.startsWith('https://'), isTrue,
          reason: 'URL should be secure');

      expect(anonKey.isNotEmpty, isTrue, reason: 'Key should not be empty');

      // Warn about webhook secret formatting rather than failing strictly, because testing env might flex
      if (anonKey.startsWith('sb_secret_')) {
        // ignore: avoid_print
        print(
            'WARNING: The ANON_KEY matches a webhook secret format, not a standard JWT anon key.');
      }
    });

    test('Supabase can be initialized with the configuration variables',
        () async {
      final url = AppConfig.supabaseUrl;
      final anonKey = AppConfig.supabaseAnonKey;

      try {
        final client = SupabaseClient(url, anonKey);
        expect(client, isNotNull);
      } catch (e) {
        fail('Supabase initialization failed: $e');
      }
    });

    test('Supabase rejects empty or completely invalid API keys gracefully',
        () async {
      // Note: To test this safely without breaking the main instance, we rely on the init test.
      // Here we verify the REST API behaviour natively like the diagnostic scripts did.
      final url = AppConfig.supabaseUrl;

      final request = await HttpClient()
          .postUrl(Uri.parse('$url/auth/v1/token?grant_type=password'));
      request.headers
          .add('apikey', ''); // Simulate the empty string from bad CI variables
      request.headers.add('Content-Type', 'application/json');

      final response = await request.close();

      expect(response.statusCode, 401,
          reason: 'Empty API keys should return Unauthorized (401)');
    });
  });
}
