import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:whispr/core/theme.dart';
import '../logic/password_bloc.dart';
import '../logic/password_event.dart';
import '../logic/password_state.dart';
import '../logic/vault_manager.dart';
import 'package:flutter/services.dart';
import 'add_password_screen.dart';
import 'vault_setup_screen.dart';
import 'vault_unlock_screen.dart';

class PasswordListScreen extends StatelessWidget {
  const PasswordListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PasswordBloc()..add(LoadPasswords()),
      child: const PasswordListBody(),
    );
  }
}

class PasswordListBody extends StatelessWidget {
  const PasswordListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordBloc, PasswordState>(
      builder: (context, state) {
        if (state is PasswordInitial || state is PasswordLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is VaultLocked) {
          return FutureBuilder<bool>(
            future: VaultManager().isVaultSetUp(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data == false) {
                return VaultSetupScreen(
                  onComplete: () {
                    context.read<PasswordBloc>().add(LoadPasswords());
                  },
                );
              }
              return VaultUnlockScreen(
                onUnlock: (pin) {
                  context.read<PasswordBloc>().add(UnlockVault(pin));
                },
              );
            },
          );
        }

        if (state is PasswordLoaded) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text('Password Vault'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.lock_outline),
                  onPressed: () =>
                      context.read<PasswordBloc>().add(LockVault()),
                ),
              ],
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: WhisprTheme.backgroundGradient,
              ),
              child: state.passwords.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        kToolbarHeight + 40,
                        24,
                        100,
                      ),
                      itemCount: state.passwords.length,
                      itemBuilder: (context, index) {
                        final password = state.passwords[index];
                        return _buildPasswordCard(context, password, state);
                      },
                    ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (c) => BlocProvider.value(
                      value: context.read<PasswordBloc>(),
                      child: const AddPasswordScreen(),
                    ),
                  ),
                );
              },
              backgroundColor: Colors.white,
              foregroundColor: WhisprTheme.backgroundColor,
              child: const Icon(Icons.add),
            ),
          );
        }

        if (state is PasswordError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  TextButton(
                    onPressed: () =>
                        context.read<PasswordBloc>().add(LoadPasswords()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Your vault is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first secure password',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(
    BuildContext context,
    dynamic password,
    PasswordLoaded state,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer.frostedGlass(
        height: 100,
        width: double.infinity,
        borderRadius: BorderRadius.circular(24),
        borderWidth: 1,
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      password.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      state.decrypt(password.usernameEncrypted),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.white38),
                onPressed: () {
                  final passValue = state.decrypt(password.passwordEncrypted);
                  Clipboard.setData(ClipboardData(text: passValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Auto-clear clipboard after 30 seconds
                  Future.delayed(const Duration(seconds: 30), () {
                    Clipboard.getData(Clipboard.kTextPlain).then((value) {
                      if (value?.text == passValue) {
                        Clipboard.setData(const ClipboardData(text: ''));
                      }
                    });
                  });
                },
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
