import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:whispr/core/theme.dart';
import '../logic/password_bloc.dart';
import '../logic/password_event.dart';
import '../logic/password_state.dart';
import '../logic/vault_manager.dart';
import 'package:flutter/services.dart';
import 'package:whispr/core/widgets/action_bottom_sheet.dart';
import 'add_password_screen.dart';
import 'vault_setup_screen.dart';
import 'vault_unlock_screen.dart';
import 'package:whispr/core/utils/snackbar_utils.dart';

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
                onBiometricUnlock: () {
                  context.read<PasswordBloc>().add(UnlockVaultWithBiometrics());
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
      child: GestureDetector(
        onTap: () => _showActionSheet(context, password, state),
        child: GlassContainer.frostedGlass(
          height: 100,
          width: MediaQuery.sizeOf(context).width - 48,
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
                  onPressed: () => _copyPassword(context, password, state),
                ),
                const Icon(Icons.more_vert, size: 20, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyPassword(
    BuildContext context,
    dynamic password,
    PasswordLoaded state,
  ) {
    final passValue = state.decrypt(password.passwordEncrypted);
    Clipboard.setData(ClipboardData(text: passValue));
    WhisprSnackBar.showSuccess(context, 'Password copied to clipboard');
    // Auto-clear clipboard after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      Clipboard.getData(Clipboard.kTextPlain).then((value) {
        if (value?.text == passValue) {
          Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    });
  }

  void _showActionSheet(
    BuildContext context,
    dynamic password,
    PasswordLoaded state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => ActionBottomSheet(
        title: password.title,
        subtitle: state.decrypt(password.usernameEncrypted),
        actions: [
          ActionItem(
            label: 'Copy Password',
            icon: Icons.copy,
            onTap: () => _copyPassword(context, password, state),
          ),
          ActionItem(
            label: 'Edit Password',
            icon: Icons.edit_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => BlocProvider.value(
                    value: context.read<PasswordBloc>(),
                    child: AddPasswordScreen(
                      password: password,
                      initialUsername: state.decrypt(
                        password.usernameEncrypted,
                      ),
                      initialPasswordValue: state.decrypt(
                        password.passwordEncrypted,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ActionItem(
            label: 'Delete Password',
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            onTap: () => _confirmDelete(context, password),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic password) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: WhisprTheme.backgroundColor,
        title: const Text('Delete Password'),
        content: Text('Are you sure you want to delete "${password.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<PasswordBloc>().add(DeletePassword(password.id));
              Navigator.pop(dialogContext);
              WhisprSnackBar.showSuccess(context, 'Password Deleted');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
