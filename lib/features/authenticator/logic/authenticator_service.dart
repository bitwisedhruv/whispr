import 'package:otp/otp.dart';
import 'dart:core';

class AuthenticatorService {
  /// Generates a 6-digit TOTP code for a given base32 secret.
  String generateTOTP(String secret) {
    try {
      return OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      return "000000";
    }
  }

  /// Calculates the remaining seconds in the current 30-second window.
  int getRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 30 - (now % 30);
  }

  /// Parses an otpauth:// URI into a map of account details.
  /// Example: otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=Google
  Map<String, String>? parseQRUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      if (parsedUri.scheme != 'otpauth' || parsedUri.host != 'totp') {
        return null;
      }

      final pathSegments = parsedUri.pathSegments;
      if (pathSegments.isEmpty) return null;

      String fullPath = pathSegments[0];
      String issuer = "";
      String accountName = "";

      if (fullPath.contains(':')) {
        final parts = fullPath.split(':');
        issuer = parts[0];
        accountName = parts[1];
      } else {
        accountName = fullPath;
      }

      final queryParams = parsedUri.queryParameters;
      final secret = queryParams['secret'];
      final queryIssuer = queryParams['issuer'];

      if (secret == null) return null;

      return {
        'issuer': queryIssuer ?? issuer,
        'accountName': accountName,
        'secret': secret,
      };
    } catch (e) {
      return null;
    }
  }
}
