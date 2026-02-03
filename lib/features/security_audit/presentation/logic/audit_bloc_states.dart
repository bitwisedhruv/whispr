import 'package:equatable/equatable.dart';
import '../../data/audit_model.dart';

abstract class AuditEvent extends Equatable {
  const AuditEvent();

  @override
  List<Object?> get props => [];
}

class StartAudit extends AuditEvent {}

abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditInitial extends AuditState {}

class AuditLoading extends AuditState {
  final String message;
  const AuditLoading({this.message = 'Analyzing vault...'});

  @override
  List<Object?> get props => [message];
}

class AuditCompleted extends AuditState {
  final AuditReport report;
  final bool isVaultLocked;

  const AuditCompleted({required this.report, required this.isVaultLocked});

  @override
  List<Object?> get props => [report, isVaultLocked];
}

class AuditError extends AuditState {
  final String message;
  const AuditError(this.message);

  @override
  List<Object?> get props => [message];
}
