import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/password_model.dart';
import '../data/password_repository.dart';
import 'encryption_service.dart';
import 'password_event.dart';
import 'password_state.dart';
import 'vault_manager.dart';
import 'package:whispr/services/supabase_service.dart';

class PasswordBloc extends Bloc<PasswordEvent, PasswordState> {
  final PasswordRepository _repository;
  final VaultManager _vaultManager = VaultManager();
  final EncryptionService _encryptionService = EncryptionService();

  PasswordBloc({PasswordRepository? repository})
      : _repository = repository ?? PasswordRepository(),
        super(PasswordInitial()) {
    on<LoadPasswords>(_onLoadPasswords);
    on<AddPassword>(_onAddPassword);
    on<UpdatePassword>(_onUpdatePassword);
    on<DeletePassword>(_onDeletePassword);
    on<UnlockVault>(_onUnlockVault);
    on<UnlockVaultWithBiometrics>(_onUnlockVaultWithBiometrics);
    on<LockVault>(_onLockVault);
    on<DeleteUnrecoverablePasswords>(_onDeleteUnrecoverablePasswords);
  }

  Future<void> _onLoadPasswords(
    LoadPasswords event,
    Emitter<PasswordState> emit,
  ) async {
    if (_vaultManager.isVaultLocked) {
      emit(VaultLocked());
      return;
    }

    emit(PasswordLoading());
    try {
      final passwords = await _repository.getPasswords();
      emit(
        PasswordLoaded(
          passwords: passwords,
          sessionKey: _vaultManager.sessionKey!,
        ),
      );
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onUnlockVault(
    UnlockVault event,
    Emitter<PasswordState> emit,
  ) async {
    final success = await _vaultManager.unlockWithPin(event.pin);
    if (success) {
      add(LoadPasswords());
    } else {
      emit(const PasswordError('Invalid PIN'));
    }
  }

  Future<void> _onUnlockVaultWithBiometrics(
    UnlockVaultWithBiometrics event,
    Emitter<PasswordState> emit,
  ) async {
    // Check if the manager already has the session key (unlocked via biometrics)
    if (!_vaultManager.isVaultLocked) {
      add(LoadPasswords());
    } else {
      emit(const PasswordError('Vault is still locked. Please try again.'));
    }
  }

  void _onLockVault(LockVault event, Emitter<PasswordState> emit) {
    _vaultManager.lockVault();
    emit(VaultLocked());
  }

  Future<void> _onAddPassword(
    AddPassword event,
    Emitter<PasswordState> emit,
  ) async {
    if (_vaultManager.isVaultLocked) {
      emit(VaultLocked());
      return;
    }

    final key = _vaultManager.sessionKey!;
    final user = SupabaseService.currentUser;
    if (user == null) {
      emit(const PasswordError('User not logged in'));
      return;
    }

    try {
      final newPassword = PasswordModel(
        userId: user.id,
        title: event.title,
        websiteUrl: event.websiteUrl,
        usernameEncrypted: _encryptionService.encryptText(event.username, key),
        passwordEncrypted: _encryptionService.encryptText(event.password, key),
        notesEncrypted: event.notes != null
            ? _encryptionService.encryptText(event.notes!, key)
            : null,
        category: event.category,
      );

      await _repository.createPassword(newPassword);
      add(LoadPasswords());
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onUpdatePassword(
    UpdatePassword event,
    Emitter<PasswordState> emit,
  ) async {
    if (_vaultManager.isVaultLocked) {
      emit(VaultLocked());
      return;
    }

    final key = _vaultManager.sessionKey!;
    try {
      var updatedPassword = event.password;

      updatedPassword = updatedPassword.copyWith(
        title: event.title,
        websiteUrl: event.websiteUrl,
      );

      // Handle nullability for notes - if event.notes is empty/null, we pass null to clear it
      // if it has content, we encrypt it.
      String? encryptedNotes;
      if (event.notes != null && event.notes!.isNotEmpty) {
        encryptedNotes = _encryptionService.encryptText(event.notes!, key);
      }
      // Since copyWith doesn't handle setting to null natively without a custom implementation,
      // we'll explicitly use the constructor if we need to set a non-null to null.
      // But actually, our copyWith does have optional parameters.
      // Let's just create a new one using the old one's data to ensure we can clear notes and other fields if needed.
      updatedPassword = PasswordModel(
        id: updatedPassword.id,
        userId: updatedPassword.userId,
        title: event.title,
        category: updatedPassword.category,
        createdAt: updatedPassword.createdAt,
        updatedAt: DateTime.now(), // update the updated_at timestamp
        websiteUrl: event.websiteUrl,
        usernameEncrypted: event.username != null
            ? _encryptionService.encryptText(event.username!, key)
            : updatedPassword.usernameEncrypted,
        passwordEncrypted: event.passwordValue != null
            ? _encryptionService.encryptText(event.passwordValue!, key)
            : updatedPassword.passwordEncrypted,
        notesEncrypted: encryptedNotes,
      );

      await _repository.updatePassword(updatedPassword);
      add(LoadPasswords());
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onDeletePassword(
    DeletePassword event,
    Emitter<PasswordState> emit,
  ) async {
    try {
      await _repository.deletePassword(event.id);
      add(LoadPasswords());
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onDeleteUnrecoverablePasswords(
    DeleteUnrecoverablePasswords event,
    Emitter<PasswordState> emit,
  ) async {
    try {
      // Delete multiple items - repository usually handles this one by one or in batch.
      // Assuming our repository can handle batch or we loop here.
      for (final id in event.ids) {
        await _repository.deletePassword(id);
      }
      add(LoadPasswords());
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }
}
