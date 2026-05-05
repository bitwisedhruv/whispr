import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/domain_report.dart';

class DomainService {
  Future<DomainReport> analyzeDomain(String domain) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'analyze-domain',
        body: {'domain': domain},
      );

      if (response.status == 200) {
        return DomainReport.fromJson(response.data);
      } else {
        throw Exception("Failed to analyze domain. Status code: ${response.status}");
      }
    } on FunctionException catch (e) {
      throw Exception("Edge function error: ${e.details}");
    } catch (e) {
      throw Exception("Error connecting to edge function: ${e.toString()}");
    }
  }
}
