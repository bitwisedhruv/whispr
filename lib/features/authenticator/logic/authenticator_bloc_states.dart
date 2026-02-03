import 'package:equatable/equatable.dart';
import '../data/authenticator_model.dart';

abstract class AuthenticatorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAuthenticators extends AuthenticatorEvent {}

class AddAuthenticator extends AuthenticatorEvent {
  final String qrUri;
  final bool force;
  final String? note;
  AddAuthenticator(this.qrUri, {this.force = false, this.note});

  @override
  List<Object?> get props => [qrUri, force, note];
}

class DeleteAuthenticator extends AuthenticatorEvent {
  final String id;
  DeleteAuthenticator(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateTimer extends AuthenticatorEvent {}

// States
abstract class AuthenticatorState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthenticatorInitial extends AuthenticatorState {}

class AuthenticatorLoading extends AuthenticatorState {}

class AuthenticatorLoaded extends AuthenticatorState {
  final List<AuthenticatorModel> accounts;
  final Map<String, String> currentCodes;
  final int remainingSeconds;

  AuthenticatorLoaded({
    required this.accounts,
    required this.currentCodes,
    required this.remainingSeconds,
  });

  @override
  List<Object?> get props => [accounts, currentCodes, remainingSeconds];
}

class AuthenticatorError extends AuthenticatorState {
  final String message;
  AuthenticatorError(this.message);

  @override
  List<Object?> get props => [message];
}

class VaultLockedError extends AuthenticatorState {}

class DuplicateDetected extends AuthenticatorState {
  final String qrUri;
  final String issuer;
  final String accountName;
  final String? note;

  DuplicateDetected({
    required this.qrUri,
    required this.issuer,
    required this.accountName,
    this.note,
  });

  @override
  List<Object?> get props => [qrUri, issuer, accountName, note];
}
