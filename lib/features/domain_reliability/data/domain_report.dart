class DomainReport {
  final String url;
  final int score;
  final String riskLevel;
  final String explanation;

  DomainReport({
    required this.url,
    required this.score,
    required this.riskLevel,
    required this.explanation,
  });

  factory DomainReport.fromJson(Map<String, dynamic> json) {
    return DomainReport(
      url: json['url']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      riskLevel: json['riskLevel']?.toString() ?? 'Unknown',
      explanation:
          json['explanation']?.toString() ?? 'No explanation provided.',
    );
  }
}
