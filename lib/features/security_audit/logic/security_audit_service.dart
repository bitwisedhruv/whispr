import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/audit_model.dart';

class SecurityAuditService {
  Future<String> getAIInterpretation(AuditReport report) async {
    final List<Map<String, dynamic>> findingsMetadata = report.findings
        .map(
          (f) => {
            'title': f.title,
            'risk_level': f.riskLevel.toString().split('.').last,
            'category': f.category,
            'context': f.accountTitle,
          },
        )
        .toList();

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'security-audit',
        body: {
          'stats': report.stats,
          'findingsMetadata': findingsMetadata,
        },
      );

      if (response.status == 200) {
        return response.data['text'] ?? "No interpretation returned.";
      } else {
        return "Failed to get AI interpretation. Status code: ${response.status}";
      }
    } on FunctionException catch (e) {
      return "Edge function error: ${e.details}";
    } catch (e) {
      return "Error connecting to edge function: ${e.toString()}";
    }
  }
}
