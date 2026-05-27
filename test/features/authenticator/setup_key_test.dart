import 'package:flutter_test/flutter_test.dart';
import 'package:whispr/features/authenticator/logic/authenticator_service.dart';

void main() {
  group('Manual Setup Key Integration & Parsing Tests', () {
    final authenticatorService = AuthenticatorService();

    test('Verification of base32 characters regex', () {
      final base32Regex = RegExp(r'^[A-Z2-7]+=*$');

      // Valid base32 secrets
      expect(base32Regex.hasMatch('JBSWY3DPEHPK3PXP'), isTrue);
      expect(base32Regex.hasMatch('JBSWY3DPEHPK3PXP==='), isTrue);

      // Invalid base32 secrets (contain invalid characters like 0, 1, 8, 9 or lowercase)
      expect(base32Regex.hasMatch('JBSWY3DPEHPK3PX8'), isFalse);
      expect(base32Regex.hasMatch('JBSWY3DPEHPK3PX0'), isFalse);
      expect(base32Regex.hasMatch('JBSWY3DPEHPK3PX9'), isFalse);
      expect(base32Regex.hasMatch('jbswy3dpehpk3pxp'), isFalse); // regex expects uppercase after normalization
      expect(base32Regex.hasMatch('JBSWY3DPEHPK3PXP!'), isFalse);
    });

    test('Strips spaces and dashes and converts to uppercase', () {
      const rawSecret = ' jbsw-y3dp-ehpk-3pxp ';
      final normalizedSecret = rawSecret.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
      expect(normalizedSecret, 'JBSWY3DPEHPK3PXP');
    });

    test('Generated manual URI parses correctly in AuthenticatorService', () {
      const issuer = 'Google';
      const accountName = 'user@gmail.com';
      const secret = 'JBSWY3DPEHPK3PXP';

      // Construct URI exactly as done in AddSetupKeyScreen
      final uri = Uri(
        scheme: 'otpauth',
        host: 'totp',
        path: '/$issuer:$accountName',
        queryParameters: {
          'secret': secret,
          'issuer': issuer,
        },
      );

      final uriString = uri.toString();
      expect(uriString, contains('otpauth://totp/Google:user@gmail.com'));
      expect(uriString, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uriString, contains('issuer=Google'));

      // Parse the generated URI back using existing AuthenticatorService
      final parsed = authenticatorService.parseQRUri(uriString);

      expect(parsed, isNotNull);
      expect(parsed!['issuer'], issuer);
      expect(parsed['accountName'], accountName);
      expect(parsed['secret'], secret);
    });
  });
}
