import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import '../logic/vault_manager.dart';

class VaultSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const VaultSetupScreen({super.key, required this.onComplete});

  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends State<VaultSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _error;

  void _setupVault() async {
    if (_pinController.text.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    if (_pinController.text != _confirmController.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    await VaultManager().setupVault(_pinController.text);
    widget.onComplete();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.lock_person_outlined,
                  size: 48,
                  color: Colors.white,
                ).animate().fadeIn().scale(),
                const SizedBox(height: 24),
                Text(
                  'Secure Your Vault',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                Text(
                  'Set a Master PIN to encrypt your data. This PIN never leaves your device.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                _buildPinField('Enter Master PIN', _pinController),
                const SizedBox(height: 16),
                _buildPinField('Confirm PIN', _confirmController),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _setupVault,
                  child: const Text('Initialize Vault'),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 6,
      style: const TextStyle(fontSize: 24, letterSpacing: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16, letterSpacing: 0),
        counterText: '',
      ),
    );
  }
}
