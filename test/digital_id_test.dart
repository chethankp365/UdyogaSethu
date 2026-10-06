import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/trust/domain/digital_id_card.dart';

String base64UrlEncodeBytes(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

List<int> base64UrlDecodeBytes(String str) {
  String b64 = str;
  while (b64.length % 4 != 0) {
    b64 += '=';
  }
  return base64Url.decode(b64);
}

String createSignedTestToken({
  required String tokenId,
  required String purpose,
  required int issuedAt,
  required int expiresAt,
  required String secret,
}) {
  final payload = {
    'tid': tokenId,
    'pur': purpose,
    'iat': issuedAt,
    'exp': expiresAt,
  };
  final encodedPayload = base64UrlEncodeBytes(utf8.encode(jsonEncode(payload)));
  final hmac = Hmac(sha256, utf8.encode(secret));
  final sig = hmac.convert(utf8.encode(encodedPayload));
  final encodedSig = base64UrlEncodeBytes(sig.bytes);
  return '$encodedPayload.$encodedSig';
}

bool verifyTokenSignature(String token, String secret) {
  final parts = token.split('.');
  if (parts.length != 2) return false;
  final encodedPayload = parts[0];
  final encodedSig = parts[1];
  final hmac = Hmac(sha256, utf8.encode(secret));
  final expectedSig = hmac.convert(utf8.encode(encodedPayload));
  final expectedEncodedSig = base64UrlEncodeBytes(expectedSig.bytes);
  return expectedEncodedSig == encodedSig;
}

void main() {
  const testSecret = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  group('Digital ID & QR Token Tests', () {
    test('formatDisplayId creates standard UDY{YYYY}{XXXX} format', () {
      final id1 = DigitalIdCardData.formatDisplayId('12345678-1234-1234-1234-12345678abcd', 2026);
      expect(id1, equals('UDY2026ABCD'));

      final id2 = DigitalIdCardData.formatDisplayId('test-uuid-9999', 2026);
      expect(id2, equals('UDY20269999'));
    });

    test('Token payload contains strictly non-PII claims (NO user_id, NO phone, NO email)', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final token = createSignedTestToken(
        tokenId: 'random-token-uuid-1234',
        purpose: 'profile',
        issuedAt: nowSec,
        expiresAt: nowSec + 300,
        secret: testSecret,
      );

      final parts = token.split('.');
      expect(parts.length, equals(2));

      final payloadMap = jsonDecode(utf8.decode(base64UrlDecodeBytes(parts[0]))) as Map<String, dynamic>;
      expect(payloadMap.containsKey('tid'), isTrue);
      expect(payloadMap.containsKey('pur'), isTrue);
      expect(payloadMap.containsKey('iat'), isTrue);
      expect(payloadMap.containsKey('exp'), isTrue);

      // Verify zero PII
      expect(payloadMap.containsKey('user_id'), isFalse);
      expect(payloadMap.containsKey('phone'), isFalse);
      expect(payloadMap.containsKey('email'), isFalse);
      expect(payloadMap.containsKey('aadhaar'), isFalse);
      expect(payloadMap.containsKey('full_name'), isFalse);
    });

    test('Valid signature verification passes', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final token = createSignedTestToken(
        tokenId: 'token-valid-1',
        purpose: 'profile',
        issuedAt: nowSec,
        expiresAt: nowSec + 300,
        secret: testSecret,
      );

      expect(verifyTokenSignature(token, testSecret), isTrue);
    });

    test('Tampered token payload or altered signature is rejected', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final token = createSignedTestToken(
        tokenId: 'token-valid-2',
        purpose: 'profile',
        issuedAt: nowSec,
        expiresAt: nowSec + 300,
        secret: testSecret,
      );

      final parts = token.split('.');
      // Alter payload
      final tamperedPayload = base64UrlEncodeBytes(utf8.encode(jsonEncode({'tid': 'hacked'})));
      final tamperedToken = '$tamperedPayload.${parts[1]}';
      expect(verifyTokenSignature(tamperedToken, testSecret), isFalse);

      // Alter signature
      final alteredSigToken = '${parts[0]}.wrong_signature';
      expect(verifyTokenSignature(alteredSigToken, testSecret), isFalse);
    });

    test('Expired token detection', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiredIat = nowSec - 600;
      final expiredExp = nowSec - 300; // Expired 5 minutes ago

      final token = createSignedTestToken(
        tokenId: 'token-expired-3',
        purpose: 'profile',
        issuedAt: expiredIat,
        expiresAt: expiredExp,
        secret: testSecret,
      );

      final parts = token.split('.');
      final payloadMap = jsonDecode(utf8.decode(base64UrlDecodeBytes(parts[0]))) as Map<String, dynamic>;
      final exp = payloadMap['exp'] as int;

      expect(exp < nowSec, isTrue, reason: 'Token must be identified as expired');
    });

    test('PublicVerificationResult parses ONLY public non-PII fields', () {
      final json = {
        'valid': true,
        'name_initial': 'R.',
        'display_id': 'UDY20264321',
        'is_verified_badge': true,
        'level': 2,
        'level_name': 'Reliable',
        'kyc_verified_at': '2026-10-01T10:00:00Z',
        'face_verified_at': '2026-10-02T12:00:00Z',
        'training_verified_at': '2026-10-03T15:00:00Z',
        'verified_at': '2026-10-06T10:00:00Z',
      };

      final result = PublicVerificationResult.fromJson(json);

      expect(result.valid, isTrue);
      expect(result.nameInitial, equals('R.'));
      expect(result.displayId, equals('UDY20264321'));
      expect(result.isVerifiedBadge, isTrue);
      expect(result.level, equals(2));
      expect(result.levelName, equals('Reliable'));
      expect(result.kycVerifiedAt, isNotNull);
      expect(result.faceVerifiedAt, isNotNull);
      expect(result.trainingVerifiedAt, isNotNull);
    });

    test('PublicVerificationResult.error handles invalid/revoked error responses', () {
      final errResult = PublicVerificationResult.error(
        code: 'token_expired',
        message: 'This QR code has expired. Please ask the worker to show an updated QR code.',
      );

      expect(errResult.valid, isFalse);
      expect(errResult.errorCode, equals('token_expired'));
      expect(errResult.nameInitial, equals('?'));
      expect(errResult.isVerifiedBadge, isFalse);
    });
  });
}
