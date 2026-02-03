import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import '../logic/vault_manager.dart';

class VaultUnlockScreen extends StatefulWidget {
  final Function(String) onUnlock;
  final VoidCallback? onBiometricUnlock;

  const VaultUnlockScreen({
    super.key,
    required this.onUnlock,
    this.onBiometricUnlock,
  });

  @override
  State<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends State<VaultUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;

  void _unlock() async {
    final success = await VaultManager().unlockWithPin(_pinController.text);
    if (success) {
      widget.onUnlock(_pinController.text);
    } else {
      setState(() => _isError = true);
      _pinController.clear();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isError = false);
      });
    }
  }

  void _unlockWithBiometrics() async {
    final success = await VaultManager().unlockWithBiometrics();
    if (success) {
      if (widget.onBiometricUnlock != null) {
        widget.onBiometricUnlock!();
      } else {
        widget.onUnlock(''); // Fallback
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _unlockWithBiometrics();
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
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: Colors.white,
                            )
                            .animate(target: _isError ? 1 : 0)
                            .shake(hz: 4, curve: Curves.easeInOut),
                        const SizedBox(height: 32),
                        Text(
                          'Vault Locked',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 48),
                        _buildPinField(),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: _unlockWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Unlock with Biometrics'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showResetConfirmation,
                          child: const Text(
                            'Forgot PIN? Reset Vault',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WhisprTheme.backgroundColor,
        title: const Text('Reset Vault?'),
        content: const Text(
          'This will permanently delete your stored PIN and salt. '
          'Your existing passwords and TOTP codes will be lost if you don\'t remember your original PIN.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await VaultManager().resetVault();
              if (mounted) {
                Navigator.pop(context);
                // Trigger a re-check or navigation to setup
                Navigator.of(
                  context,
                ).pushReplacementNamed('/'); // Go back to start
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField() {
    return TextField(
      controller: _pinController,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 32, letterSpacing: 16),
      onChanged: (val) {
        // Only auto-unlock if it's exactly 6 digits (or whatever length the user wants)
        // Removing the hardcoded 4-digit auto-unlock to fix the user's issue.
        if (val.length == 6) {
          _unlock();
        }
      },
      onSubmitted: (_) => _unlock(),
      decoration: InputDecoration(
        hintText: 'PIN',
        hintStyle: const TextStyle(fontSize: 20, letterSpacing: 0),
        counterText: '',
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: _isError ? Colors.redAccent : Colors.white24,
          ),
        ),
      ),
    );
  }
}
