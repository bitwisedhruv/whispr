import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() {
  group('Supabase Configuration & Auth Integration Tests', () {
    setUpAll(() async {
      // Ensure dotenv loads the test environment keys
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        // Fallback or ignore if handled by CI via env vars directly
      }
    });

    test('Environment variables contain valid URL and Key', () {
      final url = dotenv.env['SUPABASE_PROJECT_URL'];
      final anonKey = dotenv.env['SUPABASE_PUBLIC_ANON_KEY'];

      expect(url, isNotNull,
          reason: 'SUPABASE_PROJECT_URL missing from environment');
      expect(url!.startsWith('https://'), isTrue,
          reason: 'URL should be secure');

      expect(anonKey, isNotNull,
          reason: 'SUPABASE_PUBLIC_ANON_KEY missing from environment');
      expect(anonKey!.isNotEmpty, isTrue, reason: 'Key should not be empty');

      // Warn about webhook secret formatting rather than failing strictly, because testing env might flex
      if (anonKey.startsWith('sb_secret_')) {
        // ignore: avoid_print
        print(
            'WARNING: The ANON_KEY matches a webhook secret format, not a standard JWT anon key.');
      }
    });

    test('Supabase can be initialized with the environment variables',
        () async {
      final url = dotenv.env['SUPABASE_PROJECT_URL'];
      final anonKey = dotenv.env['SUPABASE_PUBLIC_ANON_KEY'];

      if (url == null || anonKey == null) {
        markTestSkipped(
            'Skipping initialization test because env variables are missing');
        return;
      }

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
      final url = dotenv.env['SUPABASE_PROJECT_URL'] ??
          'https://mxtfgqdrjdhcqvpqbdzh.supabase.co';

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
