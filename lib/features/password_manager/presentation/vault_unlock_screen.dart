import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import '../logic/vault_manager.dart';

class VaultUnlockScreen extends StatefulWidget {
  final Function(String) onUnlock;

  const VaultUnlockScreen({super.key, required this.onUnlock});

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
      widget.onUnlock(''); // PIN not needed if biometrics pass
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.white)
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
              ],
            ),
          ),
        ),
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
        if (val.length >= 4) {
          _unlock();
        }
      },
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
