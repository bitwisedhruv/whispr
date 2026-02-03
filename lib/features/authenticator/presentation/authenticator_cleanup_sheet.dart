import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/features/authenticator/data/authenticator_model.dart';
import 'package:whispr/features/authenticator/logic/authenticator_bloc.dart';
import 'package:whispr/features/authenticator/logic/authenticator_bloc_states.dart';
import 'package:intl/intl.dart';

class AuthenticatorCleanupSheet extends StatelessWidget {
  final List<AuthenticatorModel> duplicates;
  final Map<String, String> currentCodes;
  final int remainingSeconds;

  const AuthenticatorCleanupSheet({
    super.key,
    required this.duplicates,
    required this.currentCodes,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WhisprTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Possible Duplicates',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(fontSize: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'We found multiple codes for this account. Only one is usually active. Verify which one works and remove the obsolete codes.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: duplicates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final acc = duplicates[index];
                final code = currentCodes[acc.id] ?? '000 000';
                return _buildVerificationCard(context, acc, code);
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    AuthenticatorModel acc,
    String code,
  ) {
    String formattedCode = code;
    if (code.length == 6) {
      formattedCode = '${code.substring(0, 3)} ${code.substring(3)}';
    }

    final dateStr = acc.createdAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(acc.createdAt!)
        : 'Unknown date';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Added: $dateStr',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      if (acc.note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            acc.note!,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(context, acc),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: LinearProgressIndicator(
                      value: remainingSeconds / 30,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remainingSeconds < 5
                            ? Colors.redAccent
                            : Colors.white60,
                      ),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AuthenticatorModel acc) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: WhisprTheme.backgroundColor,
        title: const Text('Delete Code?'),
        content: const Text(
          'Ensure this code does NOT work before deleting. Deletion is permanent.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthenticatorBloc>().add(
                DeleteAuthenticator(acc.id!),
              );
              Navigator.pop(c); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: const Text(
              'Delete Obsolete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
