import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/core/utils/snackbar_utils.dart';
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
  bool _isUnlocking = false;

  void _unlock() async {
    if (_isUnlocking) return;

    setState(() => _isUnlocking = true);
    try {
      final success = await VaultManager().unlockWithPin(_pinController.text);
      if (mounted) setState(() => _isUnlocking = false);

      if (success) {
        widget.onUnlock(_pinController.text);
      } else {
        setState(() => _isError = true);
        _pinController.clear();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _isError = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUnlocking = false);
        WhisprSnackBar.showError(context, e);
      }
    }
  }

  void _unlockWithBiometrics() async {
    if (_isUnlocking) return;

    try {
      final success = await VaultManager().unlockWithBiometrics();
      // biometric auth itself handles its UI, but our key derivation is also async now
      if (success) {
        if (mounted) setState(() => _isUnlocking = true);
        // Even with biometrics, we need to derive the key from stored PIN
        // VaultManager.unlockWithBiometrics already calls deriveKey internally.
        if (widget.onBiometricUnlock != null) {
          widget.onBiometricUnlock!();
        } else {
          widget.onUnlock(''); // Fallback
        }
      }
    } catch (e) {
      if (mounted) {
        WhisprSnackBar.showError(context, e);
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
              return Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 80),
                            const Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: Colors.white,
                            )
                                .animate(target: _isError ? 1 : 0)
                                .shake(hz: 4, curve: Curves.easeInOut),
                            const SizedBox(height: 24),
                            Text(
                              'Vault Locked',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 60),
                            _buildPinField(),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUnlocking ? null : _unlock,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: _isUnlocking
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Unlock Vault'),
                              ),
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed:
                                  _isUnlocking ? null : _unlockWithBiometrics,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Unlock with Biometrics'),
                            ),
                            const SizedBox(height: 32),
                            TextButton(
                              onPressed:
                                  _isUnlocking ? null : _showResetConfirmation,
                              child: const Text(
                                'Forgot PIN? Reset Vault',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isUnlocking)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(),
                ],
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
        title: const Text(
          'RESET VAULT?',
          style:
              TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚠️ PERMANENT DATA LOSS WARNING ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Resetting your vault will delete your old encryption keys. '
              'Any passwords or TOTP accounts synced to your account will remain encrypted with the OLD key and become permanently UNREADABLE.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you don\'t remember your original PIN, this data is lost forever. You will need to delete the old entries and add them again.',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await VaultManager().resetVault();
              if (context.mounted) {
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
