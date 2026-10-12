import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';

/// Exception thrown when a user attempts to execute or queue a prohibited action while offline.
class BlockedOfflineActionException implements Exception {
  final String message;
  const BlockedOfflineActionException([
    this.message = 'Payment, verification, and QR actions require a live internet connection and cannot be queued offline.',
  ]);

  @override
  String toString() => message;
}

/// Represents a safe, non-sensitive action queued during offline periods.
class QueuedOfflineAction {
  final String id;
  final String actionType; // 'toggle_favourite', 'update_setting', 'save_draft_note'
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int retryCount;

  const QueuedOfflineAction({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action_type': actionType,
        'payload': payload,
        'queued_at': queuedAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory QueuedOfflineAction.fromJson(Map<String, dynamic> json) => QueuedOfflineAction(
        id: json['id'] as String? ?? const Uuid().v4(),
        actionType: json['action_type'] as String? ?? 'unknown',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        queuedAt: json['queued_at'] != null
            ? DateTime.tryParse(json['queued_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      );
}

/// Minimal, sanitized offline cache models storing no sensitive auth tokens or financial secrets.
class CachedJobSummary {
  final String id;
  final String title;
  final int wageRupees;
  final String status;
  final String address;
  final String employerName;
  final String? employerPhone;
  final DateTime scheduledAt;

  const CachedJobSummary({
    required this.id,
    required this.title,
    required this.wageRupees,
    required this.status,
    required this.address,
    required this.employerName,
    this.employerPhone,
    required this.scheduledAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'wage_rupees': wageRupees,
        'status': status,
        'address': address,
        'employer_name': employerName,
        'employer_phone': employerPhone,
        'scheduled_at': scheduledAt.toIso8601String(),
      };

  factory CachedJobSummary.fromJson(Map<String, dynamic> json) => CachedJobSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Job',
        wageRupees: (json['wage_rupees'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'active',
        address: json['address'] as String? ?? '',
        employerName: json['employer_name'] as String? ?? 'Employer',
        employerPhone: json['employer_phone'] as String?,
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class CachedOrderSummary {
  final String id;
  final String status;
  final int totalRupees;
  final String counterpartyName;
  final String itemsSummary;
  final DateTime createdAt;

  const CachedOrderSummary({
    required this.id,
    required this.status,
    required this.totalRupees,
    required this.counterpartyName,
    required this.itemsSummary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'total_rupees': totalRupees,
        'counterparty_name': counterpartyName,
        'items_summary': itemsSummary,
        'created_at': createdAt.toIso8601String(),
      };

  factory CachedOrderSummary.fromJson(Map<String, dynamic> json) => CachedOrderSummary(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        totalRupees: (json['total_rupees'] as num?)?.toInt() ?? 0,
        counterpartyName: json['counterparty_name'] as String? ?? 'Partner',
        itemsSummary: json['items_summary'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class CachedContactSummary {
  final String name;
  final String phone;
  final String relationship;

  const CachedContactSummary({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory CachedContactSummary.fromJson(Map<String, dynamic> json) => CachedContactSummary(
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        relationship: json['relationship'] as String? ?? 'Contact',
      );
}

/// Offline Service coordinating local storage, connectivity detection, and safe sync queues.
class OfflineCacheService {
  static const String _kKeyJobs = 'offline_cached_jobs_v1';
  static const String _kKeyOrders = 'offline_cached_orders_v1';
  static const String _kKeyContacts = 'offline_cached_contacts_v1';
  static const String _kKeyLastSync = 'offline_cached_last_sync_v1';
  static const String _kKeyActionQueue = 'offline_queued_actions_v1';

  static const Set<String> prohibitedOfflineActions = {
    'payment',
    'escrow_release',
    'upi_checkout',
    'verify_qr',
    'scan_ticket',
    'attendance_selfie',
    'ekyc_verify',
    'payout_withdrawal',
  };

  /// Validates and queues a safe action. Strictly prohibits financial & verification actions.
  Future<void> enqueueAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    if (prohibitedOfflineActions.contains(actionType.toLowerCase())) {
      throw const BlockedOfflineActionException();
    }

    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueuedActions();

    // Check for exact duplicate in queue to prevent duplicate execution
    final exists = queue.any((a) =>
        a.actionType == actionType &&
        a.payload['target_id'] == payload['target_id'] &&
        payload['target_id'] != null);

    if (exists) {
      AppLogger.i('Duplicate action $actionType for ${payload['target_id']} skipped.');
      return;
    }

    final newAction = QueuedOfflineAction(
      id: const Uuid().v4(),
      actionType: actionType,
      payload: payload,
      queuedAt: DateTime.now(),
    );

    queue.add(newAction);
    final encoded = jsonEncode(queue.map((a) => a.toJson()).toList());
    await prefs.setString(_kKeyActionQueue, encoded);
  }

  Future<List<QueuedOfflineAction>> getQueuedActions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyActionQueue);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => QueuedOfflineAction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearQueuedActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyActionQueue);
  }

  Future<void> removeQueuedAction(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getQueuedActions();
    list.removeWhere((a) => a.id == actionId);
    await prefs.setString(_kKeyActionQueue, jsonEncode(list.map((a) => a.toJson()).toList()));
  }

  // --- Caching Sanitized Jobs, Orders, Contacts ---

  Future<void> cacheTodayJobs(List<CachedJobSummary> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await prefs.setString(_kKeyJobs, data);
    await recordSyncTimestamp();
  }

  Future<List<CachedJobSummary>> getCachedTodayJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyJobs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CachedJobSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheActiveOrders(List<CachedOrderSummary> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString(_kKeyOrders, data);
    await recordSyncTimestamp();
  }

  Future<List<CachedOrderSummary>> getCachedActiveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyOrders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CachedOrderSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheEmergencyContacts(List<CachedContactSummary> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_kKeyContacts, data);
    await recordSyncTimestamp();
  }

  Future<List<CachedContactSummary>> getCachedEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyContacts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CachedContactSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> recordSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeyLastSync, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyLastSync);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyJobs);
    await prefs.remove(_kKeyOrders);
    await prefs.remove(_kKeyContacts);
    await prefs.remove(_kKeyLastSync);
    await prefs.remove(_kKeyActionQueue);
  }
}

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService();
});

/// Connectivity state: true if online, false if offline.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);

  yield* connectivity.onConnectivityChanged.map((results) {
    return !results.contains(ConnectivityResult.none);
  });
});
