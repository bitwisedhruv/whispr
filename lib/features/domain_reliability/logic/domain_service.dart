import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/domain_report.dart';

class DomainService {
  final Dio _dio;
  final String _apiKey;

  DomainService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<DomainReport> analyzeDomain(String domain) async {
    if (_apiKey.isEmpty) {
      throw Exception('AI analysis unavailable: API Key missing.');
    }

    final String url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

    final prompt = '''
You are a cybersecurity expert. Analyze the following domain/URL for reliability, phishing risks, scams, and overall safety.
Provide a risk score out of 100 (where 100 is perfectly safe and 0 is extremely dangerous).
URL to analyze: "$domain"

Respond ONLY with a valid JSON document containing the following keys:
- "url": The exact url you analyzed
- "score": integer between 0 and 100
- "riskLevel": A single word like "Safe", "Suspicious", or "Dangerous"
- "explanation": A very brief, concise explanation (1-2 sentences) of why it received this score.

Do not include markdown codeblocks like ```json ... ```. Just return the raw JSON string.
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
        String textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];

        // Clean up text response in case the model included markdown blocks
        textResponse =
            textResponse.replaceAll('```json', '').replaceAll('```', '').trim();

        final Map<String, dynamic> jsonMap = jsonDecode(textResponse);
        return DomainReport.fromJson(jsonMap);
      } else {
        throw Exception(
            "Failed to get AI interpretation. Status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      final responseBody = e.response?.data;
      throw Exception(
          "AI service error (${e.response?.statusCode}): $responseBody");
    } catch (e) {
      throw Exception("Error connecting to AI service: ${e.toString()}");
    }
  }
}
