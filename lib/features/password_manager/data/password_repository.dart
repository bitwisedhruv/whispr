import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whispr/services/supabase_service.dart';
import 'password_model.dart';

class PasswordRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<PasswordModel>> getPasswords() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('No user logged in');

    final response = await _client
        .from('passwords')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PasswordModel.fromJson(json))
        .toList();
  }

  Future<PasswordModel> createPassword(PasswordModel password) async {
    final response = await _client
        .from('passwords')
        .insert(password.toJson())
        .select()
        .single();

    return PasswordModel.fromJson(response);
  }

  Future<PasswordModel> updatePassword(PasswordModel password) async {
    if (password.id == null) {
      throw Exception('Password ID is required for update');
    }

    final response = await _client
        .from('passwords')
        .update(password.toJson()..remove('id'))
        .eq('id', password.id!)
        .select()
        .single();

    return PasswordModel.fromJson(response);
  }

  Future<void> deletePassword(String id) async {
    await _client.from('passwords').delete().eq('id', id);
  }
}
