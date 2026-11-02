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
  Future<Map<String, dynamic>> _invoke(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    HttpMethod method = HttpMethod.post,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
        queryParameters: queryParameters,
        method: method,
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
        String code = 'function_exception';
        String message = e.reasonPhrase ?? 'Edge Function error (${e.status})';
        dynamic details = e.details;

        if (details is Map) {
          final errObj = details['error'];
          if (errObj is Map) {
            code = errObj['code'] as String? ?? code;
            message = errObj['message'] as String? ?? message;
          }
        }

        throw EdgeFunctionException(
          code: code,
          statusCode: e.status,
          originalMessage: message,
          details: details,
          stackTrace: stack,
        );
      }
      throw AppException.from(e, stack);
    }
  }

  /// Run health check against a specific Edge Function (`{"health": true}`).
  Future<Map<String, dynamic>> checkFunctionHealth(String functionName) async {
    final res = await _invoke(functionName, body: {'health': true});
    final rawData = res['data'];
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return res;
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
    String? imageBase64,
  }) async {
    final body = <String, dynamic>{
      'embedding': embedding,
      'liveness_passed': livenessPassed,
      'liveness_challenges': livenessChallenges ?? [],
    };
    if (imageBase64 != null) body['image_base64'] = imageBase64;
    return _invoke('face-enroll', body: body);
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

  /// Verify user 128-float32 face embedding vector with liveness check.
  Future<Map<String, dynamic>> faceVerifyVector({
    required List<double> embedding,
    required String context,
    String? assignmentId,
    String? imageBase64,
  }) async {
    final body = <String, dynamic>{
      'embedding': embedding,
      'context': context,
    };
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    if (imageBase64 != null) body['image_base64'] = imageBase64;
    return _invoke('face-verify', body: body);
  }

  /// Call SECURITY DEFINER RPC get_face_login_requirement to check if face login is required.
  /// Flutter app MUST use this RPC and NEVER read admin_settings directly.
  Future<bool> getFaceLoginRequirement() async {
    try {
      final response = await _client.rpc('get_face_login_requirement');
      if (response is bool) return response;
      if (response is String) return response.toLowerCase() == 'true';
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Issue signed QR token for digital ID profile verification, assignment ticket check-in, or produce lot traceability.
  Future<Map<String, dynamic>> qrIssue({
    String? assignmentId,
    String? listingId,
    String? lotNumber,
    String purpose = 'profile',
  }) async {
    final body = <String, dynamic>{'purpose': purpose};
    if (assignmentId != null) body['assignment_id'] = assignmentId;
    if (listingId != null) body['listing_id'] = listingId;
    if (lotNumber != null) body['lot_number'] = lotNumber;
    return _invoke('qr-issue', body: body);
  }

  /// Verify scanned QR code for ticket check-in.
  Future<Map<String, dynamic>> qrVerify({
    required String qrToken,
    double? lat,
    double? lng,
    String? jobId,
  }) async {
    final body = <String, dynamic>{'qr_token': qrToken};
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (jobId != null) body['job_id'] = jobId;
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

  /// Two-step verified start, mid-job check, and completion with evidence.
  Future<Map<String, dynamic>> assignmentVerify({
    required String assignmentId,
    required String action,
    double? lat,
    double? lng,
    bool? isMocked,
    List<double>? embedding,
    String? selfiePath,
    List<String>? workPhotos,
    String? note,
    bool? customerConfirmed,
  }) async {
    final body = <String, dynamic>{
      'assignment_id': assignmentId,
      'action': action,
    };
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (isMocked != null) body['is_mocked'] = isMocked;
    if (embedding != null) body['embedding'] = embedding;
    if (selfiePath != null) body['selfie_path'] = selfiePath;
    if (workPhotos != null) body['work_photos'] = workPhotos;
    if (note != null) body['note'] = note;
    if (customerConfirmed != null) body['customer_confirmed'] = customerConfirmed;
    return _invoke('assignment-verify', body: body);
  }

  /// Trigger scheduled smart no-show check engine.
  Future<Map<String, dynamic>> checkNoShow() async {
    return _invoke('no-show-check');
  }

  /// Classify spoken voice command using Gemini Edge Function fallback.
  Future<Map<String, dynamic>> classifyVoiceIntent({
    required String spokenText,
    required String language,
    String? role,
  }) async {
    final body = <String, dynamic>{
      'task': 'voice_intent',
      'spoken_text': spokenText,
      'language': language,
      ...? (role != null ? {'user_role': role} : null),
    };
    return _invoke('ai-assist', body: body);
  }

  /// Query 5-Provider Orchestrated AI Assistant (Groq fast LLM, Gemini reasoning, OpenRouter fallback).
  Future<Map<String, dynamic>> queryAssistant({
    required String query,
    required String role,
    required String language,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? context,
    String? preferredProvider,
  }) async {
    final body = <String, dynamic>{
      'task': 'assistant_query',
      'spoken_text': query,
      'user_role': role,
      'language': language,
    };
    if (conversationHistory != null) body['conversation_history'] = conversationHistory;
    if (context != null) body['context'] = context;
    if (preferredProvider != null) body['preferred_provider'] = preferredProvider;
    return _invoke('ai-assist', body: body);
  }

  /// Synthesize text to natural-sounding speech via Deepgram Aura.
  Future<Map<String, dynamic>> voiceSynthesize({
    required String text,
    String? voice,
    String? language,
  }) async {
    final body = <String, dynamic>{
      'task': 'voice_tts',
      'tts_text': text,
      ...? (voice != null ? {'tts_voice': voice} : null),
      ...? (language != null ? {'language': language} : null),
    };
    return _invoke('ai-assist', body: body);
  }

  /// Transcribe speech audio to text via Deepgram Nova-2.
  Future<Map<String, dynamic>> voiceTranscribe({
    required String audioBase64,
    String? mimeType,
    String? language,
  }) async {
    final body = <String, dynamic>{
      'task': 'voice_stt',
      'audio_base64': audioBase64,
      ...? (mimeType != null ? {'audio_mime': mimeType} : null),
      ...? (language != null ? {'language': language} : null),
    };
    return _invoke('ai-assist', body: body);
  }

  /// Discover capabilities and status of all 5 configured AI providers.
  Future<Map<String, dynamic>> getAiCapabilities() async {
    return _invoke(
      'ai-assist',
      queryParameters: {'health': 'true'},
      method: HttpMethod.get,
    );
  }

  /// AI helper to generate job post title, description and requirements.
  Future<Map<String, dynamic>> generateJobDescription({
    required String category,
    String? title,
    String? notes,
    required String language,
  }) async {
    final body = <String, dynamic>{
      'task': 'job_description_helper',
      'category': category,
      'title': title,
      'notes': notes,
      'language': language,
    };
    return _invoke('ai-assist', body: body);
  }

  /// AI support chat query.
  Future<Map<String, dynamic>> supportChat({
    required String query,
    required String role,
    required String language,
  }) async {
    final body = <String, dynamic>{
      'task': 'support_chat',
      'query': query,
      'user_role': role,
      'language': language,
    };
    return _invoke('ai-assist', body: body);
  }

  /// Validate a Virtual Payment Address (UPI VPA).
  Future<Map<String, dynamic>> validateVpa(String vpa) async {
    return _invoke('validate-vpa', body: {'vpa': vpa});
  }

  /// Reconcile a payment order state against server & payment gateway.
  Future<Map<String, dynamic>> reconcilePayment(String paymentId) async {
    return _invoke('payment-reconcile', body: {'payment_id': paymentId});
  }

  /// Send or test a transactional WhatsApp notification via backend Edge Function.
  Future<Map<String, dynamic>> sendWhatsAppNotification({
    required String phone,
    required String eventType,
    String? recipientUserId,
    String? templateName,
    String? languageCode,
    List<String>? parameters,
  }) async {
    return _invoke('whatsapp-notify', body: {
      'recipient_phone': phone,
      'event_type': eventType,
      'recipient_user_id': ?recipientUserId,
      'template_name': ?templateName,
      'language_code': ?languageCode,
      'parameters': ?parameters,
    });
  }
}

/// Riverpod provider for [EdgeApiClient].
final edgeApiClientProvider = Provider<EdgeApiClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EdgeApiClient(client);
});
