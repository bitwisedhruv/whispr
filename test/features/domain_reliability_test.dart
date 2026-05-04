import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whispr/features/domain_reliability/logic/domain_service.dart';
import 'package:whispr/features/domain_reliability/data/domain_report.dart';

class MockInterceptor extends Interceptor {
  final Response response;

  MockInterceptor(this.response);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(response);
  }
}

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

  group('DomainService', () {
    test('analyzeDomain parses Gemini API response successfully', () async {
      // Create a mock JSON response simulating Gemini logic
      final mockGeminiResponse = {
        "candidates": [
          {
            "content": {
              "parts": [
                {
                  "text":
                      "{\n  \"url\": \"https://safe-domain.com\",\n  \"score\": 90,\n  \"riskLevel\": \"Safe\",\n  \"explanation\": \"Domain has strict security headers.\"\n}"
                }
              ]
            }
          }
        ]
      };

      final dio = Dio();
      dio.interceptors.add(
        MockInterceptor(
          Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: mockGeminiResponse,
          ),
        ),
      );

      final service = DomainService(dio: dio, apiKey: 'test_api_key', tavilyApiKey: '');
      final report = await service.analyzeDomain('https://safe-domain.com');

      expect(report.url, 'https://safe-domain.com');
      expect(report.score, 90);
      expect(report.riskLevel, 'Safe');
      expect(report.explanation, 'Domain has strict security headers.');
    });

    test('analyzeDomain throws an exception on API error', () async {
      final dio = Dio();
      dio.interceptors.add(
        MockInterceptor(
          Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {"error": "Internal Server Error"},
          ),
        ),
      );

      // We explicitly cause a DioException by using a stub interceptor that throws
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(
              requestOptions: options,
              statusCode: 500,
              data: {"error": "Internal Error"}),
        ));
      }));

      final service = DomainService(dio: dio, apiKey: 'test_api_key', tavilyApiKey: '');

      expect(
        () async => await service.analyzeDomain('https://bad-domain.com'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('AI service error'))),
      );
    });
  });
}
