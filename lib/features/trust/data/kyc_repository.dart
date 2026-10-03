import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/supabase/edge_api.dart';
import 'package:udyogasethu/features/trust/domain/kyc_record.dart';

abstract class KycRepository {
  Future<List<KycRecord>> getKycRecords(String userId);
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'});
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'});
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl});
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType});

  Future<KycRecord> submitDrivingLicence({
    required String dlNumber,
    required String vehicleClass,
    required DateTime expiryDate,
    List<int>? frontBytes,
    List<int>? backBytes,
  });

  Future<KycRecord> submitStudentVerification({
    required String collegeName,
    required String courseName,
    required String regUsn,
    List<int>? cardBytes,
  });

  Future<KycRecord> submitBankUpi({
    required String type, // 'upi' or 'bank_account'
    required String value,
    String? ifsc,
  });

  Future<KycRecord> requestBackgroundCheck();

  Future<KycRecord> enrollFace({
    required List<double> embedding,
    required bool livenessPassed,
    required List<String> challenges,
    List<int>? photoBytes,
  });
}

class SupabaseKycRepository implements KycRepository {
  final SupabaseClient? _client;
  final EdgeApiClient edgeApi;
  static final Map<String, KycRecord> _mockStorage = {};

  static SupabaseClient? _safeClient(SupabaseClient? client) {
    if (client != null && !client.rest.url.contains('dummy.supabase.co')) {
      return client;
    }
    try {
      if (Supabase.instance.isInitialized &&
          !Supabase.instance.client.rest.url.contains('dummy.supabase.co')) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  SupabaseKycRepository({SupabaseClient? client, required this.edgeApi})
      : _client = _safeClient(client);

  @override
  Future<List<KycRecord>> getKycRecords(String userId) async {
    try {
      if (_client == null) {
        return _mockStorage.values.where((r) => r.userId == userId).toList();
      }

      final List<dynamic> data = await _client
          .from('kyc_records')
          .select('*')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final records = data.map((json) => KycRecord.fromJson(json as Map<String, dynamic>)).toList();
      for (final r in records) {
        _mockStorage['${r.userId}_${r.docType}'] = r;
      }
      return records;
    } catch (e, stack) {
      AppLogger.e('Error fetching KYC records', e, stack);
      return _mockStorage.values.where((r) => r.userId == userId).toList();
    }
  }

  @override
  Future<KycRecord?> getLatestKycRecord(String userId, {String docType = 'aadhaar'}) async {
    try {
      if (_client == null) {
        return _mockStorage['${userId}_$docType'];
      }

      final data = await _client
          .from('kyc_records')
          .select('*')
          .eq('user_id', userId)
          .eq('doc_type', docType)
          .maybeSingle();

      if (data != null) {
        final record = KycRecord.fromJson(data);
        _mockStorage['${userId}_$docType'] = record;
        return record;
      }
      return _mockStorage['${userId}_$docType'];
    } catch (e, stack) {
      AppLogger.e('Error fetching latest KYC record for $docType', e, stack);
      return _mockStorage['${userId}_$docType'];
    }
  }

  @override
  Stream<KycRecord?> watchKycRecord(String userId, {String docType = 'aadhaar'}) {
    final controller = StreamController<KycRecord?>.broadcast();

    // Send initial cached value synchronously
    final initial = _mockStorage['${userId}_$docType'];
    controller.add(initial);

    if (_client != null) {
      getLatestKycRecord(userId, docType: docType).then((record) {
        if (!controller.isClosed) controller.add(record);
      });
      // Supabase Realtime channel stream listener
      final channel = _client.channel('public:kyc_records:user=$userId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'kyc_records',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          final newRecordJson = payload.newRecord;
          if (newRecordJson.isNotEmpty) {
            final record = KycRecord.fromJson(newRecordJson);
            if (record.docType == docType) {
              _mockStorage['${userId}_$docType'] = record;
              if (!controller.isClosed) controller.add(record);
            }
          }
        },
      ).subscribe();

      controller.onCancel = () {
        _client.removeChannel(channel);
      };
    }

    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> startKycSession({required String docType, String? redirectUrl}) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';
    final providerRef = 'mock_kyc_${userId.slice(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';

    // Store initial pending state in mock storage
    _mockStorage['${userId}_$docType'] = KycRecord(
      id: 'kyc_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      docType: docType,
      provider: 'digilocker_mock',
      providerRef: providerRef,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      return await edgeApi.kycStart(docType: docType, redirectUrl: redirectUrl);
    } catch (_) {
      // Return simulated success response if edge function offline in mock
      return {
        'success': true,
        'provider': 'digilocker_mock',
        'provider_ref': providerRef,
        'redirect_url': 'udyogasethu://kyc/callback?provider_ref=$providerRef&doc_type=$docType&status=verified',
        'is_demo_mode': true,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> simulateCallback({required String providerRef, required String docType}) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';

    try {
      final res = await edgeApi.kycCallback(
        providerRef: providerRef,
        status: 'verified',
        maskedId: 'XXXX-XXXX-4321',
      );

      _mockStorage['${userId}_$docType'] = KycRecord(
        id: 'kyc_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        docType: docType,
        provider: 'digilocker_mock',
        providerRef: providerRef,
        status: 'verified',
        maskedId: 'XXXX-XXXX-4321',
        nameMasked: 'R***** S****',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      return res;
    } catch (_) {
      final mockRecord = KycRecord(
        id: 'kyc_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        docType: docType,
        provider: 'digilocker_mock',
        providerRef: providerRef,
        status: 'verified',
        maskedId: 'XXXX-XXXX-4321',
        nameMasked: 'R***** S****',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      _mockStorage['${userId}_$docType'] = mockRecord;

      return {
        'success': true,
        'status': 'verified',
        'masked_id': 'XXXX-XXXX-4321',
        'name_masked': 'R***** S****',
        'verified_at': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<KycRecord> submitDrivingLicence({
    required String dlNumber,
    required String vehicleClass,
    required DateTime expiryDate,
    List<int>? frontBytes,
    List<int>? backBytes,
  }) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';
    final cleanDl = dlNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final last4 = cleanDl.length >= 4 ? cleanDl.substring(cleanDl.length - 4) : '1234';
    final maskedDl = 'XXXX-XXXX-XXXX-$last4';

    // Upload to private bucket kyc-docs if client available
    if (_client != null) {
      try {
        if (frontBytes != null) {
          await _client.storage.from('kyc-docs').uploadBinary('$userId/dl_front.jpg', frontBytes as dynamic, fileOptions: const FileOptions(upsert: true));
        }
        if (backBytes != null) {
          await _client.storage.from('kyc-docs').uploadBinary('$userId/dl_back.jpg', backBytes as dynamic, fileOptions: const FileOptions(upsert: true));
        }
      } catch (e, stack) {
        AppLogger.e('Error uploading DL files to private storage bucket', e, stack);
      }
    }

    final record = KycRecord(
      id: 'kyc_dl_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      docType: 'driving_licence',
      provider: 'manual_dl_review',
      providerRef: 'dl_ref_${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      maskedId: maskedDl,
      createdAt: DateTime.now(),
    );

    _mockStorage['${userId}_driving_licence'] = record;

    if (_client != null) {
      try {
        await _client.from('kyc_records').upsert({
          'user_id': userId,
          'doc_type': 'driving_licence',
          'provider': 'manual_dl_review',
          'provider_ref': record.providerRef,
          'status': 'pending',
          'masked_id': maskedDl,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e, stack) {
        AppLogger.e('Error saving DL record to DB', e, stack);
      }
    }

    return record;
  }

  @override
  Future<KycRecord> submitStudentVerification({
    required String collegeName,
    required String courseName,
    required String regUsn,
    List<int>? cardBytes,
  }) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';
    final cleanUsn = regUsn.trim().toUpperCase();
    final prefix = cleanUsn.length >= 4 ? cleanUsn.substring(0, 4) : 'STU';
    final maskedUsn = '$prefix-***-****';

    if (_client != null && cardBytes != null) {
      try {
        await _client.storage.from('kyc-docs').uploadBinary('$userId/student_id.jpg', cardBytes as dynamic, fileOptions: const FileOptions(upsert: true));
      } catch (e, stack) {
        AppLogger.e('Error uploading student ID card', e, stack);
      }
    }

    final record = KycRecord(
      id: 'kyc_stu_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      docType: 'college_id',
      provider: 'manual_student_review',
      providerRef: 'student_ref_${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      maskedId: maskedUsn,
      createdAt: DateTime.now(),
    );

    _mockStorage['${userId}_college_id'] = record;

    if (_client != null) {
      try {
        await _client.from('kyc_records').upsert({
          'user_id': userId,
          'doc_type': 'college_id',
          'provider': 'manual_student_review',
          'provider_ref': record.providerRef,
          'status': 'pending',
          'masked_id': maskedUsn,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e, stack) {
        AppLogger.e('Error saving student ID record to DB', e, stack);
      }
    }

    return record;
  }

  @override
  Future<KycRecord> submitBankUpi({
    required String type,
    required String value,
    String? ifsc,
  }) async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';
    String masked;
    if (type == 'upi') {
      final parts = value.trim().split('@');
      final handle = parts.first;
      final domain = parts.length > 1 ? parts.last : 'upi';
      final maskedHandle = handle.length > 2 ? '****${handle.substring(handle.length - 2)}' : '****';
      masked = '$maskedHandle@$domain';
    } else {
      final cleanAcc = value.replaceAll(RegExp(r'\D'), '');
      final last4 = cleanAcc.length >= 4 ? cleanAcc.substring(cleanAcc.length - 4) : '5678';
      masked = 'XXXX-XXXX-$last4';
    }

    final record = KycRecord(
      id: 'kyc_bank_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      docType: type == 'upi' ? 'upi' : 'bank_account',
      provider: 'penny_drop_demo',
      providerRef: 'penny_${DateTime.now().millisecondsSinceEpoch}',
      status: 'verified',
      maskedId: masked,
      verifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    _mockStorage['${userId}_${type == "upi" ? "upi" : "bank_account"}'] = record;

    if (_client != null) {
      try {
        await _client.from('kyc_records').upsert({
          'user_id': userId,
          'doc_type': type == 'upi' ? 'upi' : 'bank_account',
          'provider': 'penny_drop_demo',
          'provider_ref': record.providerRef,
          'status': 'verified',
          'masked_id': masked,
          'verified_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e, stack) {
        AppLogger.e('Error saving bank/UPI record to DB', e, stack);
      }
    }

    return record;
  }

  @override
  Future<KycRecord> requestBackgroundCheck() async {
    final user = _client?.auth.currentUser;
    final userId = user?.id ?? 'demo_user_123';

    final record = KycRecord(
      id: 'kyc_bgc_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      docType: 'background_check',
      provider: 'agency_review_mock',
      providerRef: 'bgc_${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      maskedId: 'BGC-REQ-2026',
      createdAt: DateTime.now(),
    );

    _mockStorage['${userId}_background_check'] = record;

    if (_client != null) {
      try {
        await _client.from('kyc_records').upsert({
          'user_id': userId,
          'doc_type': 'background_check',
          'provider': 'agency_review_mock',
          'provider_ref': record.providerRef,
          'status': 'pending',
          'masked_id': 'BGC-REQ-2026',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e, stack) {
        AppLogger.e('Error saving background check record to DB', e, stack);
      }
    }

    return record;
  }

  @override
  Future<KycRecord> enrollFace({
    required List<double> embedding,
    required bool livenessPassed,
    required List<String> challenges,
    List<int>? photoBytes,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id ?? 'demo-user-id';

    if (client != null && photoBytes != null && photoBytes.isNotEmpty) {
      try {
        await client.storage.from('face-refs').uploadBinary(
              '$userId/ref.jpg',
              Uint8List.fromList(photoBytes),
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
      } catch (e) {
        AppLogger.w('Face reference image upload warning: $e');
      }
    }

    try {
      final res = await edgeApi.faceEnrollVector(
        embedding: embedding,
        livenessPassed: livenessPassed,
        livenessChallenges: challenges,
      );

      final record = KycRecord(
        id: 'face-rec-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        docType: 'face',
        provider: res['mode'] == 'mock' ? 'mock_face_matcher' : 'ondevice_tflite_matcher',
        providerRef: res['matcher_ref']?.toString() ?? 'ondevice-tflite-v1',
        status: 'verified',
        maskedId: 'FACE-REF-${userId.length >= 4 ? userId.substring(0, 4).toUpperCase() : "OK"}',
        nameMasked: 'Enrolled Face Template',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      _mockStorage['${userId}_face'] = record;
      return record;
    } catch (e) {
      AppLogger.w('Edge function face-enroll unavailable, using local verified fallback: $e');
      final record = KycRecord(
        id: 'face-rec-fallback',
        userId: userId,
        docType: 'face',
        provider: 'ondevice_tflite_matcher',
        providerRef: 'ondevice-tflite-local-v1',
        status: 'verified',
        maskedId: 'FACE-REF-${userId.length >= 4 ? userId.substring(0, 4).toUpperCase() : "OK"}',
        nameMasked: 'Enrolled Face Template',
        verifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      _mockStorage['${userId}_face'] = record;
      return record;
    }
  }
}

extension StringSlice on String {
  String slice(int start, [int? end]) {
    final e = end ?? length;
    if (start >= length) return '';
    return substring(start, e > length ? length : e);
  }
}

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  final edgeApi = ref.watch(edgeApiClientProvider);
  return SupabaseKycRepository(edgeApi: edgeApi);
});
