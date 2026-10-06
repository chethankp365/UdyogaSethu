import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

/// Cached Signed URL entry with expiration timestamp.
class SignedUrlCacheEntry {
  final String url;
  final DateTime expiresAt;

  SignedUrlCacheEntry(this.url, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

final Map<String, SignedUrlCacheEntry> _avatarUrlCache = {};

/// Riverpod family provider for resolving storage paths to signed URLs with caching & refresh.
final avatarUrlProvider = FutureProvider.family<String?, String?>((ref, avatarPath) async {
  if (avatarPath == null || avatarPath.trim().isEmpty) {
    return null;
  }

  final path = avatarPath.trim();

  // If path is already a full HTTP/HTTPS URL
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  // Check cache for valid non-expired signed URL (buffer 5 minutes)
  final cached = _avatarUrlCache[path];
  if (cached != null && cached.expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
    return cached.url;
  }

  // Generate signed URL via Supabase Storage
  try {
    SupabaseClient? client;
    try {
      if (Supabase.instance.isInitialized) {
        client = Supabase.instance.client;
      }
    } catch (_) {}

    if (client != null && !client.rest.url.contains('dummy.supabase.co')) {
      final signedUrl = await client.storage
          .from('avatars')
          .createSignedUrl(path, 3600); // 1 hour validity

      // Cache for 50 minutes
      _avatarUrlCache[path] = SignedUrlCacheEntry(
        signedUrl,
        DateTime.now().add(const Duration(minutes: 50)),
      );

      return signedUrl;
    }
  } catch (e) {
    if (kDebugMode) {
      AppLogger.w('Failed to generate signed URL for avatarPath="$path": $e');
    }
  }

  // Fallback to public URL or raw path
  try {
    if (Supabase.instance.isInitialized) {
      return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
    }
  } catch (_) {}

  return path;
});

/// Utility helper to generate uppercase 1 or 2 letter initials from a name string.
String getInitials(String? name) {
  if (name == null || name.trim().isEmpty) return 'US';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'US';
  if (parts.length == 1) {
    final word = parts.first;
    return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.substring(0, 1).toUpperCase();
  }
  final first = parts.first[0];
  final last = parts.last[0];
  return (first + last).toUpperCase();
}

/// Unified User Avatar Widget across all screens (Profile, Seeker Home, Farmer Home, Provider Home, Wizards).
class UserAvatar extends ConsumerWidget {
  final String? avatarPath;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? fallbackIcon;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    this.radius = 32,
    this.backgroundColor,
    this.textColor,
    this.fallbackIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarAsync = ref.watch(avatarUrlProvider(avatarPath));
    final initials = getInitials(name);
    final bg = backgroundColor ?? AppColors.headerGreenDark.withAlpha(38);
    final textCol = textColor ?? AppColors.headerGreenDark;

    Widget avatarWidget = avatarAsync.when(
      data: (url) {
        if (url != null && url.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  if (kDebugMode) {
                    AppLogger.e('UserAvatar Image.network failed for url="$url" (path="$avatarPath"): $error', error, stackTrace);
                  }
                  return _buildInitialsFallback(initials, bg, textCol);
                },
              ),
            ),
          );
        }
        return _buildInitialsFallback(initials, bg, textCol);
      },
      loading: () => CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: SizedBox(
          width: radius / 2,
          height: radius / 2,
          child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
        ),
      ),
      error: (err, stack) {
        if (kDebugMode) {
          AppLogger.e('UserAvatar avatarUrlProvider error for path="$avatarPath": $err', err, stack);
        }
        return _buildInitialsFallback(initials, bg, textCol);
      },
    );

    if (onTap != null) {
      avatarWidget = GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildInitialsFallback(String initials, Color bg, Color textCol) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
      ),
    );
  }
}
