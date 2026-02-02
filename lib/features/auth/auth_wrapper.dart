import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/services/supabase_service.dart';
import 'package:whispr/features/auth/auth_page.dart';
import 'package:whispr/features/home/home_page.dart';
import 'package:whispr/features/profile/profile_setup_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = SupabaseService.client.auth.currentSession;

    if (session == null) {
      if (mounted) {
        setState(() {
          _home = const AuthPage();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profile = await SupabaseService.getProfile();
      final hasProfile =
          profile != null &&
          profile['full_name'] != null &&
          (profile['full_name'] as String).isNotEmpty;

      if (mounted) {
        setState(() {
          _home = hasProfile ? const HomePage() : const ProfileSetupPage();
          _isLoading = false;
        });
      }
    } catch (e) {
      // In case of error (e.g. network), fallback to AuthPage
      if (mounted) {
        setState(() {
          _home = const AuthPage();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: WhisprTheme.backgroundGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.2),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1, 1),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                    minHeight: 2,
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      );
    }

    return _home ?? const AuthPage();
  }
}
