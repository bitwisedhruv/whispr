import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whispr/features/password_manager/data/password_repository.dart';
import 'package:whispr/features/authenticator/data/authenticator_repository.dart';
import 'package:whispr/features/password_manager/logic/vault_manager.dart';
import '../../logic/audit_engine.dart';
import '../../logic/security_audit_service.dart';
import 'audit_bloc_states.dart';
import 'package:whispr/features/security_audit/data/audit_model.dart';

class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final PasswordRepository _passwordRepository = PasswordRepository();
  final AuthenticatorRepository _authenticatorRepository =
      AuthenticatorRepository();
  final VaultManager _vaultManager = VaultManager();
  final AuditEngine _auditEngine = AuditEngine();
  final SecurityAuditService _auditService = SecurityAuditService();

  AuditBloc() : super(AuditInitial()) {
    on<StartAudit>(_onStartAudit);
  }

  Future<void> _onStartAudit(StartAudit event, Emitter<AuditState> emit) async {
    emit(const AuditLoading());

    try {
      final passwords = await _passwordRepository.getPasswords();

      if (_vaultManager.isVaultLocked) {
        // Limited analysis for locked vault
        // We can still count passwords if we have them from repo (they are encrypted)
        // But we can't do deep analysis.
        // User requested: "If vault is locked: Show high-level audit summary only. No secret-derived details."

        final report = AuditReport(
          overallScore: 0, // Score not possible without analysis
          findings: [],
          auditDate: DateTime.now(),
          stats: {
            'total': passwords.length,
            'weak': 0,
            'reused': 0,
            'old': 0,
            'missing2FA': 0,
          },
        );
        emit(AuditCompleted(report: report, isVaultLocked: true));
        return;
      }

      // Full Analysis
      final authenticators = await _authenticatorRepository.getAuthenticators();
      final issuers = authenticators.map((a) => a.issuer).toList();

      final report = _auditEngine.performAudit(
        passwords: passwords,
        sessionKey: _vaultManager.sessionKey!,
        authenticatorIssuers: issuers,
      );

      emit(const AuditLoading(message: 'Generating AI Coach insights...'));

      final aiInterpretation = await _auditService.getAIInterpretation(report);

      final finalReport = AuditReport(
        overallScore: report.overallScore,
        findings: report.findings,
        aiInterpretation: aiInterpretation,
        auditDate: report.auditDate,
        stats: report.stats,
      );

      emit(AuditCompleted(report: finalReport, isVaultLocked: false));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }
}
