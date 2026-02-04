import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/core/theme.dart';
import 'package:whispr/features/password_manager/presentation/password_list_screen.dart';
import 'package:whispr/features/password_manager/presentation/password_generator_screen.dart';
import 'package:whispr/features/authenticator/logic/authenticator_bloc.dart';
import 'package:whispr/features/authenticator/logic/authenticator_bloc_states.dart';
import 'package:whispr/features/authenticator/presentation/qr_scanner_screen.dart';
import 'package:whispr/features/password_manager/logic/vault_manager.dart';
import 'package:whispr/features/password_manager/presentation/vault_unlock_screen.dart';
import 'package:whispr/features/security_audit/presentation/security_audit_screen.dart';
import 'package:whispr/features/authenticator/presentation/authenticator_cleanup_sheet.dart';
import 'package:whispr/features/authenticator/data/authenticator_model.dart';

import 'package:whispr/features/profile/settings_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthenticatorBloc()..add(LoadAuthenticators()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Whispr'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: WhisprTheme.backgroundGradient,
          ),
          child: BlocBuilder<AuthenticatorBloc, AuthenticatorState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: kToolbarHeight + 40),
                    Text(
                      'Authenticator',
                      style: Theme.of(context).textTheme.displayMedium,
                    ).animate().fadeIn().slideX(begin: -0.1),
                    const SizedBox(height: 24),

                    BlocListener<AuthenticatorBloc, AuthenticatorState>(
                      listener: (context, state) {
                        if (state is DuplicateDetected) {
                          _showDuplicateWarning(context, state);
                        }
                      },
                      child: Container(),
                    ),

                    if (state is AuthenticatorLoading)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            height: 24,
                            width: 100,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white30,
                              ),
                              minHeight: 1,
                            ),
                          ),
                        ),
                      ).animate().fadeIn()
                    else if (state is VaultLockedError)
                      _buildLockedState(context)
                    else if (state is AuthenticatorLoaded)
                      state.accounts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'No accounts added yet. Tap + to add one.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            )
                          : _buildAuthenticatorList(context, state)
                    else if (state is AuthenticatorError)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              state.message,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            TextButton(
                              onPressed: () => context
                                  .read<AuthenticatorBloc>()
                                  .add(LoadAuthenticators()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 48),
                    Text(
                      'Quick Tools',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),
                    _buildToolCard(
                      context,
                      'Password Vault',
                      'Access your secure encrypted credentials',
                      Icons.lock_outline,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PasswordListScreen(),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    _buildToolCard(
                      context,
                      'Password Generator',
                      'Generate ultra-secure phrases',
                      Icons.key_outlined,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const PasswordGeneratorScreen(),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    _buildToolCard(
                      context,
                      'Security Audit',
                      'Check for compromised passes',
                      Icons.security_outlined,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SecurityAuditScreen(),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
                if (result != null && context.mounted) {
                  final note = await _showAddNoteDialog(context);
                  if (context.mounted) {
                    context.read<AuthenticatorBloc>().add(
                      AddAuthenticator(result, note: note),
                    );
                  }
                }
              },
              backgroundColor: Colors.white,
              foregroundColor: WhisprTheme.backgroundColor,
              child: const Icon(Icons.add),
            ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack);
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticatorList(
    BuildContext context,
    AuthenticatorLoaded state,
  ) {
    // Group accounts by issuer + accountName
    Map<String, List<AuthenticatorModel>> grouped = {};
    for (var acc in state.accounts) {
      final key =
          '${acc.issuer.toLowerCase()}:${acc.accountName.toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(acc);
    }

    return Column(
      children: grouped.values.map((list) {
        final primary = list.first;
        final hasDuplicates = list.length > 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildOTPCard(
            context,
            primary.issuer,
            primary.accountName,
            state.currentCodes[primary.id] ?? '000 000',
            state.remainingSeconds,
            isDuplicate: hasDuplicates,
            onCleanup: hasDuplicates
                ? () => _showCleanupSheet(
                    context,
                    list,
                    state.currentCodes,
                    state.remainingSeconds,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOTPCard(
    BuildContext context,
    String title,
    String subtitle,
    String code,
    int remainingSeconds, {
    bool isDuplicate = false,
    VoidCallback? onCleanup,
  }) {
    String formattedCode = code;
    if (code.length == 6) {
      formattedCode = '${code.substring(0, 3)} ${code.substring(3)}';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDuplicate
              ? Colors.orangeAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        if (isDuplicate)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.orangeAccent,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedCode,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
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
          if (isDuplicate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '⚠️ Multiple codes detected',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onCleanup,
                    child: const Text(
                      'Verify & clean up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white24, size: 32),
          const SizedBox(height: 16),
          const Text(
            'Vault is Locked',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Text(
            'Unlock to view your 2FA codes',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showUnlockVault(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: WhisprTheme.backgroundColor,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Unlock Vault'),
          ),
        ],
      ),
    );
  }

  void _showUnlockVault(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: WhisprTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: VaultUnlockScreen(
          onUnlock: (pin) async {
            final success = await VaultManager().unlockWithPin(pin);
            if (success && context.mounted) {
              context.read<AuthenticatorBloc>().add(LoadAuthenticators());
              Navigator.pop(context);
            }
          },
          onBiometricUnlock: () {
            context.read<AuthenticatorBloc>().add(LoadAuthenticators());
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCleanupSheet(
    BuildContext context,
    List<AuthenticatorModel> list,
    Map<String, String> currentCodes,
    int remainingSeconds,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => BlocProvider.value(
        value: context.read<AuthenticatorBloc>(),
        child: AuthenticatorCleanupSheet(
          duplicates: list,
          currentCodes: currentCodes,
          remainingSeconds: remainingSeconds,
        ),
      ),
    );
  }

  void _showDuplicateWarning(BuildContext context, DuplicateDetected state) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: WhisprTheme.backgroundColor,
        title: const Text('Duplicate Detected'),
        content: Text(
          'This account (${state.issuer}: ${state.accountName}) already has an authenticator entry. You may now have multiple codes. After confirming login works, consider removing the old one.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.read<AuthenticatorBloc>().add(LoadAuthenticators());
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.read<AuthenticatorBloc>().add(
                AddAuthenticator(state.qrUri, force: true, note: state.note),
              );
            },
            child: const Text(
              'Add Anyway',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showAddNoteDialog(BuildContext context) async {
    String? note;
    return await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: WhisprTheme.backgroundColor,
        title: const Text('Add Note (Optional)'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => note = v,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g., Re-added after reset',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Skip', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, note),
            child: const Text('Next', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF475569)),
          ],
        ),
      ),
    );
  }
}
