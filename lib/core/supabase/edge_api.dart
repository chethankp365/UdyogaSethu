import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/supabase_service.dart';

/// Response wrapper returned by [EdgeApiClient].
class EdgeResponse<T> {
  final bool success;
  final T? data;
  final String? errorCode;
  final String? errorMessage;
  final dynamic details;

  const EdgeResponse({
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.details,
  });

  factory EdgeResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) parseData) {
    final success = json['success'] as bool? ?? false;
    if (success) {
      return EdgeResponse(
        success: true,
        data: json['data'] != null ? parseData(json['data']) : null,
      );
    }
    final error = json['error'] as Map<String, dynamic>?;
    return EdgeResponse(
      success: false,
      errorCode: error?['code'] as String? ?? 'unknown_error',
      errorMessage: error?['message'] as String? ?? 'An unexpected error occurred',
      details: error?['details'],
    );
  }
}

/// Client service for calling Supabase Edge Functions.
class EdgeApiClient {
  final SupabaseClient _client;

  EdgeApiClient(this._client);

  /// Helper to invoke edge function and map response/exceptions to [AppException].
  Future<Map<String, dynamic>> _invoke(String functionName, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );

      final status = response.status;
      final rawData = response.data;

      Map<String, dynamic> dataMap = {};
      if (rawData is Map<String, dynamic>) {
        dataMap = rawData;
      } else if (rawData is Map) {
        dataMap = Map<String, dynamic>.from(rawData);
      }

      if (status >= 400 || (dataMap.containsKey('success') && dataMap['success'] == false)) {
        final error = dataMap['error'] as Map<String, dynamic>?;
        final code = error?['code'] as String? ?? 'http_error_$status';
        final message = error?['message'] as String? ?? 'Edge function returned status $status';
        final details = error?['details'];

        throw EdgeFunctionException(
          code: code,
          statusCode: status,
          originalMessage: message,
          details: details,
        );
      }

      return dataMap;
    } catch (e, stack) {
      if (e is AppException) {
        rethrow;
      }
      if (e is FunctionException) {
        throw EdgeFunctionException(
          code: 'function_exception',
          statusCode: e.status,
          originalMessage: e.reasonPhrase ?? e.toString(),
          details: e.details,
          stackTrace: stack,
        );
      }
      throw AppException.from(e, stack);
    }
  }

  /// P1.8 Functions

  /// Initiate KYC verification process for Aadhaar, PAN, DL, or Voter ID.
  Future<Map<String, dynamic>> kycStart({required String docType, String? redirectUrl}) async {
    final body = <String, dynamic>{'doc_type': docType};
    if (redirectUrl != null) body['redirect_url'] = redirectUrl;
    return _invoke('kyc-start', body: body);
  }

  /// Receive partner KYC status callback updates.
  Future<Map<String, dynamic>> kycCallback({
    required String providerRef,
    required String status,
    String? maskedId,
  }) async {
    final body = <String, dynamic>{
      'provider_ref': providerRef,
      'status': status,
    };
    if (maskedId != null) body['masked_id'] = maskedId;
    return _invoke('kyc-callback', body: body);
  }

  /// Enroll user face embedding for biometric verification.
  Future<Map<String, dynamic>> faceEnroll({required String imageBase64}) async {
    return _invoke('face-enroll', body: {'image_base64': imageBase64});
  }

  /// Enroll user 128-float32 face embedding vector with liveness verification.
  Future<Map<String, dynamic>> faceEnrollVector({
    required List<double> embedding,
    required bool livenessPassed,
    List<String>? livenessChallenges,
  }) async {
    return _invoke('face-enroll', body: {
      'embedding': embedding,
      'liveness_passed': livenessPassed,
      'liveness_challenges': livenessChallenges ?? [],
    });
  }

  /// Verify user selfie against registered face embedding.
  Future<Map<String, dynamic>> faceVerify({
    required String imageBase64,
    required String targetUserId,
  }) async {
    return _invoke('face-verify', body: {
      'image_base64': imageBase64,
      'target_user_id': targetUserId,
    });
  }

  /// Issue signed QR token for assignment ticket check-in.
  Future<Map<String, dynamic>> qrIssue({required String assignmentId}) async {
    return _invoke('qr-issue', body: {'assignment_id': assignmentId});
  }

  /// Verify scanned QR code for ticket check-in.
  Future<Map<String, dynamic>> qrVerify({
    required String qrToken,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{'qr_token': qrToken};
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    return _invoke('qr-verify', body: body);
  }

  /// Create Razorpay payment order for escrow, buying, or subscription.
  Future<Map<String, dynamic>> paymentCreateOrder({
    required String refType,
    required String refId,
    required int amountPaise,
  }) async {
    return _invoke('payment-create-order', body: {
      'ref_type': refType,
      'ref_id': refId,
      'amount_paise': amountPaise,
    });
  }

  /// Webhook receiver for Razorpay payment notifications.
  Future<Map<String, dynamic>> paymentWebhook({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    return _invoke('payment-webhook', body: {
      'event': event,
      'payload': payload,
    });
  }

  /// Trigger emergency SOS alert with user location.
  Future<Map<String, dynamic>> sosTrigger({
    required double lat,
    required double lng,
    String? message,
    String? assignmentId,
  }) async {
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
    };
    if (message != null) body['message'] = message;
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    return _invoke('sos-trigger', body: body);
  }

  /// Send FCM push notification to specific user.
  Future<Map<String, dynamic>> sendPush({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final reqBody = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'body': body,
    };
    if (data != null) reqBody['data'] = data;
    return _invoke('send-push', body: reqBody);
  }

  /// Trigger Mandi crop price sync.
  Future<Map<String, dynamic>> mandiSync({String? state, String? commodity}) async {
    final body = <String, dynamic>{};
    if (state != null) body['state'] = state;
    if (commodity != null) body['commodity'] = commodity;
    return _invoke('mandi-sync', body: body);
  }

  /// Call Gemini AI assistant for voice & text natural language tasks.
  Future<Map<String, dynamic>> aiAssist({
    required String prompt,
    Map<String, dynamic>? context,
    String? language,
  }) async {
    final body = <String, dynamic>{'prompt': prompt};
    if (context != null) body['context'] = context;
    if (language != null) body['language'] = language;
    return _invoke('ai-assist', body: body);
  }

  /// Connect masked private phone call between provider and worker.
  Future<Map<String, dynamic>> maskedCall({
    required String recipientId,
    String? assignmentId,
  }) async {
    final body = <String, dynamic>{'recipient_id': recipientId};
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    return _invoke('masked-call', body: body);
  }
}

/// Riverpod provider for [EdgeApiClient].
final edgeApiClientProvider = Provider<EdgeApiClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EdgeApiClient(client);
});
