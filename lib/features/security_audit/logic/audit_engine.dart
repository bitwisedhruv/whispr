import 'dart:math';
import 'package:whispr/features/password_manager/data/password_model.dart';
import 'package:whispr/features/password_manager/logic/encryption_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:whispr/features/authenticator/data/authenticator_model.dart';
import '../data/audit_model.dart';

class AuditEngine {
  final EncryptionService _encryptionService = EncryptionService();

  AuditReport performAudit({
    required List<PasswordModel> passwords,
    required List<AuthenticatorModel> authenticators,
    required encrypt.Key sessionKey,
  }) {
    List<AuditFinding> findings = [];
    int totalPasswords = passwords.length;
    int weakCount = 0;
    int reusedCount = 0;
    int oldCount = 0;
    int missing2FACount = 0;
    int duplicateTOTPCount = 0;

    Map<String, List<PasswordModel>> passwordGroups = {};

    final authenticatorIssuers = authenticators.map((a) => a.issuer).toList();

    for (var pwd in passwords) {
      final decryptedPassword = _encryptionService.decryptText(
        pwd.passwordEncrypted,
        sessionKey,
      );

      // 1. Password Strength & Entropy
      double entropy = _calculateEntropy(decryptedPassword);
      if (entropy < 40 || decryptedPassword.length < 8) {
        weakCount++;
        findings.add(
          AuditFinding(
            title: 'Weak Password',
            description:
                'The password for "${pwd.title}" has low entropy or is too short.',
            riskLevel: entropy < 25 ? RiskLevel.critical : RiskLevel.high,
            accountId: pwd.id,
            accountTitle: pwd.title,
            category: pwd.category ?? 'General',
          ),
        );
      }

      // 2. Reuse Detection (Grouping)
      passwordGroups.putIfAbsent(decryptedPassword, () => []).add(pwd);

      // 3. Age Detection
      if (pwd.createdAt != null) {
        final ageInDays = DateTime.now().difference(pwd.createdAt!).inDays;
        if (ageInDays > 365) {
          oldCount++;
          findings.add(
            AuditFinding(
              title: 'Old Password',
              description:
                  'The password for "${pwd.title}" hasn\'t been changed in over a year.',
              riskLevel: RiskLevel.medium,
              accountId: pwd.id,
              accountTitle: pwd.title,
              category: pwd.category ?? 'General',
            ),
          );
        }
      }

      // 4. Missing 2FA Check (Heuristic)
      bool has2FA = authenticatorIssuers.any(
        (issuer) =>
            pwd.title.toLowerCase().contains(issuer.toLowerCase()) ||
            (pwd.websiteUrl?.toLowerCase().contains(issuer.toLowerCase()) ??
                false),
      );

      if (!has2FA && _isHighRiskCategory(pwd.category)) {
        missing2FACount++;
        findings.add(
          AuditFinding(
            title: 'Missing 2FA',
            description:
                'No matching authenticator found for "${pwd.title}", which is a high-risk account.',
            riskLevel: RiskLevel.medium,
            accountId: pwd.id,
            accountTitle: pwd.title,
            category: pwd.category ?? 'General',
          ),
        );
      }
    }

    // Process Reuse Findings
    passwordGroups.forEach((pwd, list) {
      if (list.length > 1) {
        reusedCount += list.length;
        for (var item in list) {
          findings.add(
            AuditFinding(
              title: 'Reused Password',
              description:
                  'This password is used across ${list.length} different accounts.',
              riskLevel: RiskLevel.high,
              accountId: item.id,
              accountTitle: item.title,
              category: item.category ?? 'General',
            ),
          );
        }
      }
    });

    // 5. Duplicate TOTP Check
    Map<String, List<AuthenticatorModel>> totpGroups = {};
    for (var auth in authenticators) {
      final key =
          '${auth.issuer.toLowerCase()}:${auth.accountName.toLowerCase()}';
      totpGroups.putIfAbsent(key, () => []).add(auth);
    }

    totpGroups.forEach((key, list) {
      if (list.length > 1) {
        duplicateTOTPCount += (list.length - 1);
        for (var item in list) {
          findings.add(
            AuditFinding(
              title: 'Duplicate TOTP',
              description:
                  'Multiple authenticator entries found for "${item.issuer} (${item.accountName})". Only one is usually active.',
              riskLevel: RiskLevel.medium,
              accountId: item.id,
              accountTitle: '${item.issuer} (${item.accountName})',
              category: 'Authenticator',
            ),
          );
        }
      }
    });

    // Calculate Overall Score (Simplified)
    int score = _calculateScore(
      total: totalPasswords,
      weak: weakCount,
      reused: reusedCount,
      old: oldCount,
      missing2FA: missing2FACount,
      duplicateTOTP: duplicateTOTPCount,
    );

    return AuditReport(
      overallScore: score,
      findings: findings,
      auditDate: DateTime.now(),
      stats: {
        'total': totalPasswords,
        'weak': weakCount,
        'reused': reusedCount,
        'old': oldCount,
        'missing2FA': missing2FACount,
        'duplicateTOTP': duplicateTOTPCount,
      },
    );
  }

  double _calculateEntropy(String password) {
    if (password.isEmpty) return 0;
    Set<String> charset = {};
    for (int i = 0; i < password.length; i++) {
      charset.add(password[i]);
    }

    int poolSize = 0;
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasLower) poolSize += 26;
    if (hasUpper) poolSize += 26;
    if (hasDigits) poolSize += 10;
    if (hasSpecial) poolSize += 32;

    if (poolSize == 0) poolSize = charset.length;

    return (password.length * (log(poolSize) / log(2)));
  }

  bool _isHighRiskCategory(String? category) {
    if (category == null) return false;
    final c = category.toLowerCase();
    return c.contains('banking') ||
        c.contains('financial') ||
        c.contains('email') ||
        c.contains('identity') ||
        c.contains('primary');
  }

  int _calculateScore({
    required int total,
    required int weak,
    required int reused,
    required int old,
    required int missing2FA,
    required int duplicateTOTP,
  }) {
    if (total == 0) return 100;

    double penalty = 0;
    penalty += (weak / total) * 40;
    penalty += (reused / total) * 30;
    penalty += (old / total) * 10;
    penalty += (missing2FA / total) * 20;
    penalty += (duplicateTOTP > 0 ? 5 : 0); // Small flat penalty for duplicates

    int score = 100 - penalty.round();
    return score.clamp(0, 100);
  }
}
