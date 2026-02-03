import 'package:equatable/equatable.dart';

enum RiskLevel { low, medium, high, critical }

class AuditFinding extends Equatable {
  final String title;
  final String description;
  final RiskLevel riskLevel;
  final String? accountId;
  final String? accountTitle;
  final String category;

  const AuditFinding({
    required this.title,
    required this.description,
    required this.riskLevel,
    this.accountId,
    this.accountTitle,
    required this.category,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    riskLevel,
    accountId,
    accountTitle,
    category,
  ];
}

class AuditReport extends Equatable {
  final int overallScore; // 0-100
  final List<AuditFinding> findings;
  final String? aiInterpretation;
  final DateTime auditDate;
  final Map<String, int> stats; // e.g., {'total': 10, 'weak': 2, ...}

  const AuditReport({
    required this.overallScore,
    required this.findings,
    this.aiInterpretation,
    required this.auditDate,
    required this.stats,
  });

  @override
  List<Object?> get props => [
    overallScore,
    findings,
    aiInterpretation,
    auditDate,
    stats,
  ];
}
