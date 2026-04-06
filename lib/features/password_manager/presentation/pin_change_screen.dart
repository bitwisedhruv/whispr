import 'package:flutter/material.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/core/utils/snackbar_utils.dart';
import '../logic/vault_manager.dart';
import '../logic/encryption_service.dart';
import '../data/password_repository.dart';
import 'package:whispr/features/authenticator/data/authenticator_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/password_bloc.dart';
import '../logic/password_event.dart';
import 'package:whispr/features/authenticator/logic/authenticator_bloc.dart';
import 'package:whispr/features/authenticator/logic/authenticator_bloc_states.dart' as auth_states;

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleUpdatePin() async {
    final oldPin = _oldPinController.text;
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (newPin.length < 4) {
      WhisprSnackBar.showError(context, 'New PIN must be at least 4 digits');
      return;
    }

    if (newPin != confirmPin) {
      WhisprSnackBar.showError(context, 'New PINs do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vaultManager = VaultManager();
      final encryptionService = EncryptionService();

      // 1. Verify old PIN
      final isOldPinCorrect = await vaultManager.verifyPin(oldPin);
      if (!isOldPinCorrect) {
        throw Exception('Current PIN is incorrect');
      }

      // 2. Fetch all data using current session key
      final passwordRepo = PasswordRepository();
      final authRepo = AuthenticatorRepository();

      final currentPasswords = await passwordRepo.getPasswords();
      final currentAuths = await authRepo.getAuthenticators();

      // 3. Decrypt everything with old key
      final oldKey = vaultManager.sessionKey!;
      
      // 4. Temporarily derive the new key to ensure it works
      final salt = await vaultManager.getSalt() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final newKey = await encryptionService.deriveKey(newPin, salt);

      // 5. Re-encrypt all Passwords
      for (final p in currentPasswords) {
        final username = encryptionService.decryptText(p.usernameEncrypted, oldKey);
        final passVal = encryptionService.decryptText(p.passwordEncrypted, oldKey);
        final notes = p.notesEncrypted != null 
            ? encryptionService.decryptText(p.notesEncrypted!, oldKey) 
            : null;

        final updatedP = p.copyWith(
          usernameEncrypted: encryptionService.encryptText(username, newKey),
          passwordEncrypted: encryptionService.encryptText(passVal, newKey),
          notesEncrypted: notes != null ? encryptionService.encryptText(notes, newKey) : null,
        );
        await passwordRepo.updatePassword(updatedP);
      }

      // 6. Re-encrypt all Authenticators
      for (final a in currentAuths) {
        final secret = encryptionService.decryptText(a.encryptedSecret, oldKey);
        final updatedA = a.copyWith(
          encryptedSecret: encryptionService.encryptText(secret, newKey),
        );
        await authRepo.updateAuthenticator(updatedA);
      }

      // 7. Finally, update the PIN in vault manager
      await vaultManager.changePin(newPin);

      if (mounted) {
        WhisprSnackBar.showSuccess(context, 'Vault PIN updated successfully');
        // Refresh Blocs
        context.read<PasswordBloc>().add(LoadPasswords());
        context.read<AuthenticatorBloc>().add(auth_states.LoadAuthenticators());
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
        title: const Text('Change Vault PIN'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your data will be re-encrypted with your new PIN. This protects your vault if you choose to update your security.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                _buildPinField('Current PIN', _oldPinController),
                const SizedBox(height: 16),
                _buildPinField('New PIN', _newPinController),
                const SizedBox(height: 16),
                _buildPinField('Confirm New PIN', _confirmPinController),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdatePin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: WhisprTheme.backgroundColor),
                          )
                        : const Text('Update PIN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(color: Colors.white24, letterSpacing: 8),
          ),
        ),
      ],
    );
  }
}
