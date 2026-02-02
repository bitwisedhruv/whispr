import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase (Call this in main.dart)
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

    final url = dotenv.env['SUPABASE_PROJECT_URL'];
    final anonKey = dotenv.env['SUPABASE_PUBLIC_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception('Supabase credentials not found in .env file');
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  // Auth Methods
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  // Profile Methods
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  static Future<void> updateProfile(String fullName, String avatarUrl) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    await client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<String> uploadAvatar(File file) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    final fileExt = file.path.split('.').last;
    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = fileName;

    await client.storage
        .from('avatars')
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return client.storage.from('avatars').getPublicUrl(filePath);
  }
}
