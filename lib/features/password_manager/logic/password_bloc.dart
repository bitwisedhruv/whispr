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
    on<LockVault>(_onLockVault);
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

      if (event.username != null) {
        updatedPassword = updatedPassword.copyWith(
          usernameEncrypted: _encryptionService.encryptText(
            event.username!,
            key,
          ),
        );
      }

      if (event.passwordValue != null) {
        updatedPassword = updatedPassword.copyWith(
          passwordEncrypted: _encryptionService.encryptText(
            event.passwordValue!,
            key,
          ),
        );
      }

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
}
