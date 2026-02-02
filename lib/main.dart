import 'package:flutter/material.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/features/auth/auth_wrapper.dart';
import 'package:whispr/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (User needs to add credentials in SupabaseService)
  await SupabaseService.init();

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
