import 'package:equatable/equatable.dart';
import '../data/password_model.dart';
import 'encryption_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

abstract class PasswordState extends Equatable {
  const PasswordState();

  @override
  List<Object?> get props => [];
}

class PasswordInitial extends PasswordState {}

class VaultLocked extends PasswordState {}

class PasswordLoading extends PasswordState {}

class PasswordLoaded extends PasswordState {
  final List<PasswordModel> passwords;
  final encrypt.Key sessionKey;

  const PasswordLoaded({required this.passwords, required this.sessionKey});

  @override
  List<Object?> get props => [passwords, sessionKey];

  /// Helper to decrypt a password locally
  String decrypt(String ciphertext) {
    return EncryptionService().decryptText(ciphertext, sessionKey);
  }
}

class PasswordError extends PasswordState {
  final String message;

  const PasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordAddedState extends PasswordState {}

class PasswordUpdatedState extends PasswordState {}

class PasswordDeletedState extends PasswordState {}
