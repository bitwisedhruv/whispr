import 'package:flutter/material.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/core/utils/snackbar_utils.dart';
import 'package:whispr/services/supabase_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleUpdatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 6) {
      WhisprSnackBar.showError(context, 'Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      WhisprSnackBar.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.updateUserPassword(newPassword);
      if (mounted) {
        WhisprSnackBar.showSuccess(context, 'Account password updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        WhisprSnackBar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Changing your account password will update how you sign in to Whispr on all devices.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                _buildPasswordField('New Password', _newPasswordController),
                const SizedBox(height: 16),
                _buildPasswordField('Confirm New Password', _confirmPasswordController),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdatePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: WhisprTheme.backgroundColor),
                          )
                        : const Text('Update Account Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
      ],
    );
  }
}
