import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/booked_slot.dart';
import '../domain/user_address.dart';
import '../domain/booking_draft.dart';
import '../domain/booking_result.dart';
import '../domain/recurring_booking.dart';

class BookingConflictException implements Exception {
  final String message;
  const BookingConflictException(this.message);
  @override
  String toString() => message;
}

class WageBandInfo {
  final int minPaise;
  final int maxPaise;
  final String unit;

  const WageBandInfo({
    required this.minPaise,
    required this.maxPaise,
    required this.unit,
  });
}

abstract class BookingRepository {
  Future<List<BookedSlot>> fetchWorkerBookedSlots(String workerId, DateTime startDate, DateTime endDate);
  Future<List<UserAddress>> fetchSavedAddresses();
  Future<UserAddress> saveAddress(UserAddress address);
  Future<BookingResult> submitDirectBooking(BookingDraft draft);
  Future<List<RecurringBooking>> fetchRecurringBookings();
  Future<bool> updateRecurringBooking(String id, {String? status, String? scheduleRule, String? preferredTime});
  Future<bool> skipRecurringBookingDate(String id, DateTime skipDate);
  Future<WageBandInfo?> fetchWageBand({required String categoryId, String? area});
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return SupabaseBookingRepository(Supabase.instance.client);
});

class SupabaseBookingRepository implements BookingRepository {
  final SupabaseClient _client;

  SupabaseBookingRepository(this._client);

  @override
  Future<List<BookedSlot>> fetchWorkerBookedSlots(String workerId, DateTime startDate, DateTime endDate) async {
    try {
      final res = await _client.rpc('get_worker_booked_slots', params: {
        'p_worker_id': workerId,
        'p_start_date': startDate.toIso8601String().split('T').first,
        'p_end_date': endDate.toIso8601String().split('T').first,
      });

      if (res is List) {
        return res.map((item) => BookedSlot.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('SupabaseBookingRepository.fetchWorkerBookedSlots error: $e');
      return _mockBookedSlots(workerId, startDate);
    }
  }

  @override
  Future<List<UserAddress>> fetchSavedAddresses() async {
    try {
      final res = await _client.rpc('get_user_addresses');
      if (res is List) {
        return res.map((item) => UserAddress.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
      return _mockAddresses();
    } catch (e) {
      debugPrint('SupabaseBookingRepository.fetchSavedAddresses error: $e');
      return _mockAddresses();
    }
  }

  @override
  Future<UserAddress> saveAddress(UserAddress address) async {
    try {
      final res = await _client.rpc('save_user_address', params: {
        'p_label': address.label,
        'p_line1': address.line1,
        'p_landmark': address.landmark,
        'p_city': address.city,
        'p_pincode': address.pincode,
        'p_lat': address.lat,
        'p_lng': address.lng,
        'p_is_default': address.isDefault,
      });
      final id = res?.toString() ?? 'addr-${DateTime.now().millisecondsSinceEpoch}';
      return UserAddress(
        id: id,
        userId: _client.auth.currentUser?.id ?? 'user-demo',
        label: address.label,
        line1: address.line1,
        landmark: address.landmark,
        city: address.city,
        pincode: address.pincode,
        lat: address.lat,
        lng: address.lng,
        isDefault: address.isDefault,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('SupabaseBookingRepository.saveAddress error: $e');
      return address;
    }
  }

  @override
  Future<BookingResult> submitDirectBooking(BookingDraft draft) async {
    try {
      final res = await _client.rpc('request_worker', params: {
        'p_worker_id': draft.workerId,
        'p_category_id': draft.categoryId,
        'p_title': draft.title.isNotEmpty ? draft.title : '${draft.categoryName} Service',
        'p_start_at': draft.startAt.toIso8601String(),
        'p_agreed_wage_paise': draft.wagePaise,
        'p_est_duration_minutes': draft.durationMinutes,
        'p_address_text': draft.effectiveAddressText,
        'p_lat': draft.effectiveLat,
        'p_lng': draft.effectiveLng,
        'p_payment_mode': draft.paymentMode,
        'p_protection_selected': draft.isProtectionSelected,
        'p_recurring_rule': draft.isRecurring ? draft.recurringRule : null,
        'p_preferred_time': draft.isRecurring
            ? '${draft.selectedTimeHour.toString().padLeft(2, '0')}:${draft.selectedTimeMinute.toString().padLeft(2, '0')}:00'
            : null,
      });

      if (res is Map) {
        return BookingResult.fromJson(Map<String, dynamic>.from(res));
      } else if (res is String) {
        final decoded = jsonDecode(res);
        if (decoded is Map) {
          return BookingResult.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      return BookingResult(
        assignmentId: 'asgn-${DateTime.now().millisecondsSinceEpoch}',
        jobId: 'job-${DateTime.now().millisecondsSinceEpoch}',
        bookingCode: 'BOOK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        status: 'requested',
        protectionSelected: draft.isProtectionSelected,
        startAt: draft.startAt,
      );
    } on PostgrestException catch (e) {
      if (e.code == 'P4001' || e.message.contains('already booked')) {
        throw BookingConflictException(e.message);
      }
      rethrow;
    } catch (e) {
      if (e.toString().contains('already booked')) {
        throw BookingConflictException(e.toString());
      }
      debugPrint('SupabaseBookingRepository.submitDirectBooking fallback: $e');
      // For demo / offline test fallback
      return BookingResult(
        assignmentId: 'asgn-demo-${DateTime.now().millisecondsSinceEpoch}',
        jobId: 'job-demo-${DateTime.now().millisecondsSinceEpoch}',
        bookingCode: 'BOOK-DEMO1',
        status: 'requested',
        protectionSelected: draft.isProtectionSelected,
        startAt: draft.startAt,
        recurringId: draft.isRecurring ? 'rec-demo-1' : null,
      );
    }
  }

  @override
  Future<List<RecurringBooking>> fetchRecurringBookings() async {
    try {
      final res = await _client.rpc('get_provider_recurring_bookings');
      if (res is List) {
        return res.map((item) => RecurringBooking.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
      return _mockRecurringBookings();
    } catch (e) {
      debugPrint('SupabaseBookingRepository.fetchRecurringBookings error: $e');
      return _mockRecurringBookings();
    }
  }

  @override
  Future<bool> updateRecurringBooking(String id, {String? status, String? scheduleRule, String? preferredTime}) async {
    try {
      final res = await _client.rpc('update_recurring_booking', params: {
        'p_recurring_id': id,
        'p_status': status,
        'p_schedule_rule': scheduleRule,
        'p_preferred_time': preferredTime,
      });
      return res as bool? ?? true;
    } catch (e) {
      debugPrint('SupabaseBookingRepository.updateRecurringBooking error: $e');
      return true;
    }
  }

  @override
  Future<bool> skipRecurringBookingDate(String id, DateTime skipDate) async {
    try {
      final res = await _client.rpc('skip_recurring_booking_date', params: {
        'p_recurring_id': id,
        'p_skip_date': skipDate.toIso8601String().split('T').first,
      });
      return res as bool? ?? true;
    } catch (e) {
      debugPrint('SupabaseBookingRepository.skipRecurringBookingDate error: $e');
      return true;
    }
  }

  @override
  Future<WageBandInfo?> fetchWageBand({required String categoryId, String? area}) async {
    try {
      final res = await _client.rpc('suggest_wage_band', params: {
        'p_category_id': categoryId,
        'p_area': area ?? 'default',
      });
      if (res is List && res.isNotEmpty) {
        final first = res.first as Map;
        return WageBandInfo(
          minPaise: (first['min_paise'] as num).toInt(),
          maxPaise: (first['max_paise'] as num).toInt(),
          unit: first['unit']?.toString() ?? 'day',
        );
      }
    } catch (e) {
      debugPrint('SupabaseBookingRepository.fetchWageBand error: $e');
    }
    return null;
  }

  List<BookedSlot> _mockBookedSlots(String workerId, DateTime date) {
    // Tomorrow from 14:00 to 18:00
    final tomorrow = date.add(const Duration(days: 1));
    return [
      BookedSlot(
        assignmentId: 'asgn-mock-1',
        jobId: 'job-mock-1',
        startAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0),
        endAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 0),
        status: 'accepted',
      ),
    ];
  }

  List<UserAddress> _mockAddresses() {
    return const [
      UserAddress(
        id: 'addr-1',
        userId: 'user-demo',
        label: 'Home',
        line1: 'Flat 402, Green Glen Layout, Bellandur',
        landmark: 'Near Central Mall',
        city: 'Bengaluru',
        pincode: '560103',
        lat: 12.9260,
        lng: 77.6762,
        isDefault: true,
      ),
      UserAddress(
        id: 'addr-2',
        userId: 'user-demo',
        label: 'Site Office',
        line1: 'Plot 45, Phase 2, Electronic City',
        landmark: 'Opposite Infosys Gate 1',
        city: 'Bengaluru',
        pincode: '560100',
        lat: 12.8452,
        lng: 77.6602,
        isDefault: false,
      ),
    ];
  }

  List<RecurringBooking> _mockRecurringBookings() {
    return [
      RecurringBooking(
        id: 'rec-1',
        providerId: 'user-demo',
        workerId: 'worker-1',
        workerName: 'Chethan Kumar',
        workerAvatar: null,
        categoryId: 'cat-electrician',
        categoryName: 'Electrician',
        scheduleRule: 'weekly',
        preferredTime: '09:00:00',
        status: 'active',
        skipDates: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];
  }
}
