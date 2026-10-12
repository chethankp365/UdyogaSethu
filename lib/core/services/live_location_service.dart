// Service: LiveLocationService (Step P7.3)
// Live location sharing while a job is active, stopped automatically on completion

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';

class LiveLocationState {
  final bool isSharing;
  final String? activeBookingCode;
  final Position? lastPosition;
  final DateTime? lastUpdatedAt;

  const LiveLocationState({
    this.isSharing = false,
    this.activeBookingCode,
    this.lastPosition,
    this.lastUpdatedAt,
  });

  LiveLocationState copyWith({
    bool? isSharing,
    String? activeBookingCode,
    Position? lastPosition,
    DateTime? lastUpdatedAt,
  }) {
    return LiveLocationState(
      isSharing: isSharing ?? this.isSharing,
      activeBookingCode: activeBookingCode ?? this.activeBookingCode,
      lastPosition: lastPosition ?? this.lastPosition,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class LiveLocationNotifier extends Notifier<LiveLocationState> {
  StreamSubscription<Position>? _positionSubscription;

  @override
  LiveLocationState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
    });
    return const LiveLocationState();
  }

  Future<void> startSharing({required String bookingCode}) async {
    if (state.isSharing && state.activeBookingCode == bookingCode) return;

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        AppLogger.w('LiveLocation: Location permission denied, cannot start live sharing.');
        return;
      }

      state = state.copyWith(isSharing: true, activeBookingCode: bookingCode);

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // 20m updates
        ),
      ).listen(
        (position) {
          state = state.copyWith(
            lastPosition: position,
            lastUpdatedAt: DateTime.now(),
          );
        },
        onError: (err) {
          AppLogger.e('LiveLocation: stream error', err);
        },
      );
    } catch (e) {
      AppLogger.e('LiveLocation: failed to start sharing', e);
    }
  }

  Future<void> stopSharing() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    state = const LiveLocationState(isSharing: false);
  }
}

final liveLocationProvider =
    NotifierProvider<LiveLocationNotifier, LiveLocationState>(
  LiveLocationNotifier.new,
);
