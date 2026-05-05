import 'package:flutter_test/flutter_test.dart';
import 'package:whispr/features/domain_reliability/data/domain_report.dart';

void main() {
  group('DomainReport', () {
    test('fromJson handles valid data correctly', () {
      final json = {
        "url": "https://example.com",
        "score": 85,
        "riskLevel": "Safe",
        "explanation": "This is a safe test domain."
      };

      final report = DomainReport.fromJson(json);

      expect(report.url, "https://example.com");
      expect(report.score, 85);
      expect(report.riskLevel, "Safe");
      expect(report.explanation, "This is a safe test domain.");
    });

    test('fromJson handles missing data gracefully', () {
      final json = <String, dynamic>{}; // empty map

      final report = DomainReport.fromJson(json);

      expect(report.url, "");
      expect(report.score, 0);
      expect(report.riskLevel, "Unknown");
      expect(report.explanation, "No explanation provided.");
    });
  });
}
