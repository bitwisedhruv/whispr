import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/core/theme.dart';
import '../logic/password_bloc.dart';
import '../logic/password_event.dart';
import 'dart:math';
import 'package:whispr/features/password_manager/data/password_model.dart';
import 'package:whispr/core/utils/snackbar_utils.dart';

class AddPasswordScreen extends StatefulWidget {
  final String? initialUsername;
  final String? initialPasswordValue;
  final PasswordModel? password;
  const AddPasswordScreen({
    super.key,
    this.initialUsername,
    this.initialPasswordValue,
    this.password,
  });

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  late final TextEditingController _passwordController;
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.password != null) {
      _titleController.text = widget.password!.title;
      _urlController.text = widget.password!.websiteUrl ?? '';
      _usernameController.text = widget.initialUsername ?? '';
      _passwordController = TextEditingController(
        text: widget.initialPasswordValue,
      );
    } else {
      _passwordController = TextEditingController(
        text: widget.initialPasswordValue,
      );
    }
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
      WhisprSnackBar.showError(
        context,
        'Please fill in title, username, and password',
      );
      return;
    }

    if (widget.password != null) {
      context.read<PasswordBloc>().add(
        UpdatePassword(
          password: widget.password!,
          username: _usernameController.text,
          passwordValue: _passwordController.text,
        ),
      );
    } else {
      context.read<PasswordBloc>().add(
        AddPassword(
          title: _titleController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          websiteUrl: _urlController.text.isNotEmpty
              ? _urlController.text
              : null,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        ),
      );
    }

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
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.white38,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }
}
