import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/services/supabase_service.dart';
import 'package:whispr/features/home/home_page.dart';
import 'package:whispr/features/profile/profile_setup_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await SupabaseService.signIn(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await SupabaseService.signUp(
          _emailController.text,
          _passwordController.text,
        );
      }

      final user = SupabaseService.currentUser;
      if (user == null) {
        if (!_isLogin) {
          throw Exception(
            'Sign up successful! Please check your email for a confirmation link.',
          );
        } else {
          throw Exception('Login failed. Please check your credentials.');
        }
      }

      // Check for profile completeness
      final profile = await SupabaseService.getProfile();
      final hasProfile =
          profile != null &&
          profile['full_name'] != null &&
          (profile['full_name'] as String).isNotEmpty;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                hasProfile ? const HomePage() : const ProfileSetupPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ).animate().scale(
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                      'Whispr',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.displayLarge,
                                    )
                                    .animate()
                                    .fadeIn(delay: 200.ms)
                                    .slideY(begin: 0.2),
                                const SizedBox(height: 8),
                                Text(
                                  'Secure your world. Silently.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ).animate().fadeIn(delay: 400.ms),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _isLogin ? 'Welcome Back' : 'Create Account',
                            style: Theme.of(context).textTheme.displayMedium,
                          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                            ),
                          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                          const SizedBox(height: 32),
                          ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: WhisprTheme.backgroundColor,
                                        ),
                                      )
                                    : Text(_isLogin ? 'Log In' : 'Sign Up'),
                              )
                              .animate()
                              .fadeIn(delay: 900.ms)
                              .scale(begin: const Offset(0.9, 0.9)),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin
                                    ? 'New to Whispr? Create Account'
                                    : 'Already have an account? Log In',
                              ),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
