import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/features/password_manager/logic/encryption_service.dart';
import 'package:whispr/features/password_manager/logic/vault_manager.dart';
import 'package:whispr/services/supabase_service.dart';

import '../data/authenticator_model.dart';
import '../data/authenticator_repository.dart';
import 'authenticator_bloc_states.dart';
import 'authenticator_service.dart';

class AuthenticatorBloc extends Bloc<AuthenticatorEvent, AuthenticatorState> {
  final AuthenticatorRepository _repository;
  final AuthenticatorService _authenticatorService = AuthenticatorService();
  final VaultManager _vaultManager = VaultManager();
  final EncryptionService _encryptionService = EncryptionService();

  Timer? _refreshTimer;

  AuthenticatorBloc({AuthenticatorRepository? repository})
    : _repository = repository ?? AuthenticatorRepository(),
      super(AuthenticatorInitial()) {
    on<LoadAuthenticators>(_onLoadAuthenticators);
    on<AddAuthenticator>(_onAddAuthenticator);
    on<DeleteAuthenticator>(_onDeleteAuthenticator);
    on<UpdateTimer>(_onUpdateTimer);
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadAuthenticators(
    LoadAuthenticators event,
    Emitter<AuthenticatorState> emit,
  ) async {
    if (_vaultManager.isVaultLocked) {
      emit(
        AuthenticatorError('Vault is locked. Please unlock to view 2FA codes.'),
      );
      return;
    }

    emit(AuthenticatorLoading());
    try {
      final accounts = await _repository.getAuthenticators();
      _startTimer();
      _emitLoadedState(emit, accounts);
    } catch (e) {
      emit(AuthenticatorError(e.toString()));
    }
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(UpdateTimer());
    });
  }

  Future<void> _onUpdateTimer(
    UpdateTimer event,
    Emitter<AuthenticatorState> emit,
  ) async {
    if (state is AuthenticatorLoaded) {
      final currentState = state as AuthenticatorLoaded;
      _emitLoadedState(emit, currentState.accounts);
    }
  }

  void _emitLoadedState(
    Emitter<AuthenticatorState> emit,
    List<AuthenticatorModel> accounts,
  ) {
    if (_vaultManager.isVaultLocked) return;

    final key = _vaultManager.sessionKey!;
    final Map<String, String> codes = {};

    for (var acc in accounts) {
      try {
        final secret = _encryptionService.decryptText(acc.encryptedSecret, key);
        codes[acc.id!] = _authenticatorService.generateTOTP(secret);
      } catch (e) {
        codes[acc.id!] = "Error";
      }
    }

    emit(
      AuthenticatorLoaded(
        accounts: accounts,
        currentCodes: codes,
        remainingSeconds: _authenticatorService.getRemainingSeconds(),
      ),
    );
  }

  Future<void> _onAddAuthenticator(
    AddAuthenticator event,
    Emitter<AuthenticatorState> emit,
  ) async {
    if (_vaultManager.isVaultLocked) return;

    final parsed = _authenticatorService.parseQRUri(event.qrUri);
    if (parsed == null) {
      emit(AuthenticatorError('Invalid QR Code format.'));
      return;
    }

    final user = SupabaseService.currentUser;
    if (user == null) return;

    final key = _vaultManager.sessionKey!;

    try {
      final encryptedSecret = _encryptionService.encryptText(
        parsed['secret']!,
        key,
      );

      final newAccount = AuthenticatorModel(
        userId: user.id,
        issuer: parsed['issuer']!,
        accountName: parsed['accountName']!,
        encryptedSecret: encryptedSecret,
      );

      await _repository.createAuthenticator(newAccount);
      add(LoadAuthenticators());
    } catch (e) {
      emit(AuthenticatorError('Failed to add account: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAuthenticator(
    DeleteAuthenticator event,
    Emitter<AuthenticatorState> emit,
  ) async {
    try {
      await _repository.deleteAuthenticator(event.id);
      add(LoadAuthenticators());
    } catch (e) {
      emit(AuthenticatorError(e.toString()));
    }
  }
}
