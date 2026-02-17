import 'package:flutter/material.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/features/auth/auth_wrapper.dart';
import 'package:whispr/services/supabase_service.dart';

import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.init();

  // Handle deep links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'myapp' && uri.host == 'login') {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        // Supabase will automatically handle the session restoration from the URL fragment
      });
    }
  });

  runApp(const WhisprApp());
}

class WhisprApp extends StatelessWidget {
  const WhisprApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whispr',
      theme: WhisprTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
