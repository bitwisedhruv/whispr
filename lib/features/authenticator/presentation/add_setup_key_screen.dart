import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/core/utils/snackbar_utils.dart';

class AddSetupKeyScreen extends StatefulWidget {
  const AddSetupKeyScreen({super.key});

  @override
  State<AddSetupKeyScreen> createState() => _AddSetupKeyScreenState();
}

class _AddSetupKeyScreenState extends State<AddSetupKeyScreen> {
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _notesController = TextEditingController();
  bool _obscureSecret = true;

  @override
  void dispose() {
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final issuer = _issuerController.text.trim();
    final account = _accountController.text.trim();
    final rawSecret = _secretController.text;
    final notes = _notesController.text.trim();

    if (issuer.isEmpty) {
      WhisprSnackBar.showError(context, 'Issuer is required (e.g. Google, GitHub)');
      return;
    }

    if (account.isEmpty) {
      WhisprSnackBar.showError(context, 'Account Name is required (e.g. your email)');
      return;
    }

    // Normalize Secret Key: Remove all spaces/dashes and convert to uppercase
    final normalizedSecret = rawSecret.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

    if (normalizedSecret.isEmpty) {
      WhisprSnackBar.showError(context, 'Secret Key is required');
      return;
    }

    // Base32 Validation Regex (A-Z, 2-7, optional = padding)
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    if (!base32Regex.hasMatch(normalizedSecret)) {
      WhisprSnackBar.showError(
        context,
        'Invalid Secret Key format. Base32 keys should only contain letters A-Z and digits 2-7.',
      );
      return;
    }

    // Build standard otpauth URI
    final uri = Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '/$issuer:$account',
      queryParameters: {
        'secret': normalizedSecret,
        'issuer': issuer,
      },
    );

    // Return the generated URI and optional notes back to the caller
    Navigator.of(context).pop({
      'uri': uri.toString(),
      'note': notes.isNotEmpty ? notes : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Enter Setup Key'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 24,
            24,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Account Details'),
              const SizedBox(height: 16),
              _buildField(
                'Issuer',
                _issuerController,
                hintText: 'e.g. Google, GitHub, Supabase',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 20),
              _buildField(
                'Account Name / Email',
                _accountController,
                hintText: 'e.g. user@gmail.com',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Key Settings'),
              const SizedBox(height: 16),
              _buildSecretField(),
              const SizedBox(height: 20),
              _buildField(
                'Notes (Optional)',
                _notesController,
                hintText: 'e.g. Primary backup code',
                icon: Icons.notes,
                maxLines: 2,
              ),
            ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WhisprTheme.secondaryTextColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required String hintText,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSecretField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Secret Key', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _secretController,
          obscureText: _obscureSecret,
          style: const TextStyle(color: Colors.white, letterSpacing: 1.5),
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Enter 16 or 32 character key',
            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSecret
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white38,
              ),
              onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
            ),
          ),
        ),
      ],
    );
  }
}
