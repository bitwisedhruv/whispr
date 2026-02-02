import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/core/theme.dart';
import '../logic/password_bloc.dart';
import '../logic/password_event.dart';
import 'dart:math';

class AddPasswordScreen extends StatefulWidget {
  final String? initialPassword;
  const AddPasswordScreen({super.key, this.initialPassword});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  late final TextEditingController _passwordController;
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.initialPassword);
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();
    final pass = List.generate(
      16,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    setState(() => _passwordController.text = pass);
  }

  void _save() {
    if (_titleController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title, username, and password'),
        ),
      );
      return;
    }

    context.read<PasswordBloc>().add(
      AddPassword(
        title: _titleController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        websiteUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Add Password'),
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
          padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 40, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Title', _titleController, icon: Icons.title),
              const SizedBox(height: 20),
              _buildField(
                'Website URL (Optional)',
                _urlController,
                icon: Icons.link,
              ),
              const SizedBox(height: 20),
              _buildField(
                'Username / Email',
                _usernameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildField(
                'Notes (Optional)',
                _notesController,
                icon: Icons.notes,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
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
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password', style: Theme.of(context).textTheme.bodyMedium),
            TextButton.icon(
              onPressed: _generatePassword,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Generate'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: false, // User might want to see what they generated
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, size: 20),
          ),
        ),
      ],
    );
  }
}
