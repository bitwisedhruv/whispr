import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/services/supabase_service.dart';
import 'package:whispr/features/auth/auth_page.dart';
import 'package:whispr/features/profile/profile_edit_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            children: [
              _buildSectionHeader(context, 'Account'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                'Edit Profile',
                'Change your name and avatar',
                Icons.person_outline,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileEditScreen(),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
              const SizedBox(height: 16),
              _buildSettingsCard(
                context,
                'Log Out',
                'Sign out of your account',
                Icons.logout_rounded,
                onTap: () async {
                  final confirm = await _showConfirmDialog(
                    context,
                    title: 'Log Out',
                    message: 'Are you sure you want to log out?',
                    confirmLabel: 'Log Out',
                  );
                  if (confirm == true) {
                    await SupabaseService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthPage(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Danger Zone'),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                'Delete Account',
                'Permanently remove your account and data',
                Icons.delete_forever_outlined,
                color: Colors.redAccent,
                onTap: () async {
                  final confirm = await _showConfirmDialog(
                    context,
                    title: 'Delete Account',
                    message:
                        'THIS ACTION IS PERMANENT. All your data including vault and 2FA secrets will be lost. Are you absolutely sure?',
                    confirmLabel: 'Delete Permanently',
                    isDangerous: true,
                  );
                  if (confirm == true) {
                    try {
                      await SupabaseService.deleteUserAccount();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AuthPage(),
                          ),
                          (route) => false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deleted successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final themeColor = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: themeColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: themeColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: themeColor.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: themeColor.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WhisprTheme.backgroundColor,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDangerous ? Colors.redAccent : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
