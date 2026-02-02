import 'package:equatable/equatable.dart';
import '../data/password_model.dart';

abstract class PasswordEvent extends Equatable {
  const PasswordEvent();

  @override
  List<Object?> get props => [];
}

class LoadPasswords extends PasswordEvent {}

class AddPassword extends PasswordEvent {
  final String title;
  final String username;
  final String password;
  final String? websiteUrl;
  final String? notes;
  final String? category;

  const AddPassword({
    required this.title,
    required this.username,
    required this.password,
    this.websiteUrl,
    this.notes,
    this.category,
  });

  @override
  List<Object?> get props => [
    title,
    username,
    password,
    websiteUrl,
    notes,
    category,
  ];
}

class UpdatePassword extends PasswordEvent {
  final PasswordModel password;
  final String? username;
  final String? passwordValue;

  const UpdatePassword({
    required this.password,
    this.username,
    this.passwordValue,
  });

  @override
  List<Object?> get props => [password, username, passwordValue];
}

class DeletePassword extends PasswordEvent {
  final String id;

  const DeletePassword(this.id);

  @override
  List<Object?> get props => [id];
}

class LockVault extends PasswordEvent {}

class UnlockVault extends PasswordEvent {
  final String pin;

  const UnlockVault(this.pin);

  @override
  List<Object?> get props => [pin];
}
