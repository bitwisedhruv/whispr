import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/audit_model.dart';

class SecurityAuditService {
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> getAIInterpretation(AuditReport report) async {
    if (_apiKey.isEmpty) {
      return "AI analysis unavailable: API Key missing.";
    }

    final String url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

    // Prepare metadata for AI
    final List<Map<String, dynamic>> findingsMetadata = report.findings
        .map(
          (f) => {
            'title': f.title,
            'risk_level': f.riskLevel.toString().split('.').last,
            'category': f.category,
            'context': f
                .accountTitle, // Providing the title is okay as per constraints ("Only send AI: Password metadata... Category... Pattern fingerprints or similarity signals")
          },
        )
        .toList();

    final prompt =
        '''
You are a Security Coach. Analyze the following password vault audit results and provide a brief, actionable, and encouraging interpretation.
Explain why these risks matter in simple language and prioritize what the user should fix first.

DRY RUN STATS:
Total Accounts: ${report.stats['total']}
Weak Passwords: ${report.stats['weak']}
Reused Passwords: ${report.stats['reused']}
Old Passwords: ${report.stats['old']}
Missing 2FA: ${report.stats['missing2FA']}
Duplicate TOTP Entries: ${report.stats['duplicateTOTP']}

FINDINGS:
${findingsMetadata.map((f) => "- ${f['title']} (${f['risk_level']}) in ${f['category']} for account '${f['context']}'").join('\n')}

INSTRUCTIONS:
- Use encouraging, non-fear-mongering language.
- Use phrasing like "Potential risk", "Common attack pattern", "Recommended improvement".
- Do NOT make false guarantees.
- Focus on education and progress.
- Keep it concise (max 200 words).
''';

    try {
      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Failed to get AI interpretation. Status code: ${response.statusCode}";
      }
    } on DioException catch (e) {
      final responseBody = e.response?.data;
      return "AI service error (${e.response?.statusCode}): $responseBody";
    } catch (e) {
      return "Error connecting to AI service: ${e.toString()}";
    }
  }
}
