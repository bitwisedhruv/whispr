import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whispr/services/supabase_service.dart';
import 'authenticator_model.dart';

class AuthenticatorRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<AuthenticatorModel>> getAuthenticators() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('No user logged in');

    final response = await _client
        .from('authenticators')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AuthenticatorModel.fromJson(json))
        .toList();
  }

  Future<AuthenticatorModel> createAuthenticator(
    AuthenticatorModel authenticator,
  ) async {
    final response = await _client
        .from('authenticators')
        .insert(authenticator.toJson())
        .select()
        .single();

    return AuthenticatorModel.fromJson(response);
  }

  Future<void> deleteAuthenticator(String id) async {
    await _client.from('authenticators').delete().eq('id', id);
  }
}
