import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:udyogasethu/core/services/offline_cache_service.dart';

/// Wraps application screens to display a non-intrusive offline / reconnecting banner.
class OfflineBannerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  ConsumerState<OfflineBannerWrapper> createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends ConsumerState<OfflineBannerWrapper> {
  bool _wasOffline = false;
  bool _showReconnected = false;
  DateTime? _lastSync;

  @override
  Widget build(BuildContext context) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final isOnline = onlineAsync.value ?? true;

    if (!isOnline && !_wasOffline) {
      _wasOffline = true;
      _showReconnected = false;
      ref.read(offlineCacheServiceProvider).getLastSyncTimestamp().then((val) {
        if (mounted) setState(() => _lastSync = val);
      });
    } else if (isOnline && _wasOffline) {
      _wasOffline = false;
      _showReconnected = true;
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showReconnected = false;
          });
        }
      });
    }

    final syncFormatted = _lastSync != null
        ? DateFormat('hh:mm a').format(_lastSync!)
        : 'recently';

    return Column(
      children: [
        if (!isOnline)
          Material(
            color: const Color(0xFFD97706),
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline Mode • Viewing cached data (Synced: $syncFormatted). Money & QR actions disabled.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_showReconnected)
          Material(
            color: const Color(0xFF0D6548),
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Back Online • Authoritative connection restored.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
