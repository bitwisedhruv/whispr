import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:whispr/core/theme.dart';
import 'add_password_screen.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  double _length = 16;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String allowedChars = '';
    if (_useUppercase) allowedChars += upper;
    if (_useLowercase) allowedChars += lower;
    if (_useNumbers) allowedChars += numbers;
    if (_useSymbols) allowedChars += symbols;

    if (allowedChars.isEmpty) {
      setState(() => _generatedPassword = 'Select options');
      return;
    }

    final random = Random.secure();
    final password = List.generate(
      _length.toInt(),
      (index) => allowedChars[random.nextInt(allowedChars.length)],
    ).join();

    setState(() => _generatedPassword = password);
  }

  double _calculateStrength() {
    if (_generatedPassword.isEmpty || _generatedPassword == 'Select options') {
      return 0.0;
    }

    double strength = 0.0;
    if (_length > 8) strength += 0.2;
    if (_length > 12) strength += 0.2;
    if (_length > 20) strength += 0.1;

    int variety = 0;
    if (_useUppercase) variety++;
    if (_useLowercase) variety++;
    if (_useNumbers) variety++;
    if (_useSymbols) variety++;

    strength += (variety / 4) * 0.5;

    return strength.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.4) return Colors.redAccent;
    if (strength < 0.7) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _getStrengthText(double strength) {
    if (strength < 0.4) return 'Weak';
    if (strength < 0.7) return 'Good';
    return 'Very Strong';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    final strengthColor = _getStrengthColor(strength);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Password Generator')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: WhisprTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _buildDisplayArea(strengthColor),
                const SizedBox(height: 32),
                _buildStrengthIndicator(strength, strengthColor),
                const SizedBox(height: 40),
                _buildConfigSection(),
                const SizedBox(height: 48),
                _buildActionButtons(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayArea(Color accentColor) {
    return GlassContainer.frostedGlass(
      height: 120,
      width: MediaQuery.sizeOf(context).width - 48,
      borderRadius: BorderRadius.circular(24),
      borderWidth: 1,
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _generatedPassword,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white60),
              onPressed: _generate,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }

  Widget _buildStrengthIndicator(double strength, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Security Level',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              _getStrengthText(strength),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Length: ${_length.toInt()}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _length,
          min: 8,
          max: 64,
          divisions: 56,
          activeColor: Colors.white,
          inactiveColor: Colors.white12,
          onChanged: (value) {
            setState(() => _length = value);
            _generate();
          },
        ),
        const SizedBox(height: 24),
        _buildToggle(
          'Include Uppercase (A-Z)',
          _useUppercase,
          (v) => setState(() => _useUppercase = v),
        ),
        _buildToggle(
          'Include Lowercase (a-z)',
          _useLowercase,
          (v) => setState(() => _useLowercase = v),
        ),
        _buildToggle(
          'Include Numbers (0-9)',
          _useNumbers,
          (v) => setState(() => _useNumbers = v),
        ),
        _buildToggle(
          'Include Symbols (!#@)',
          _useSymbols,
          (v) => setState(() => _useSymbols = v),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Switch(
            value: value,
            onChanged: (v) {
              onChanged(v);
              _generate();
            },
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _generatedPassword));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Password'),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    AddPasswordScreen(initialPassword: _generatedPassword),
              ),
            );
          },
          icon: const Icon(Icons.add_moderator),
          label: const Text('Add to Vault'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}
