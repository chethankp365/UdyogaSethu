import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/errors/app_exception.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

/// Riverpod family provider for resolving storage paths to public URLs with caching.
final avatarUrlProvider = FutureProvider.family<String?, String?>((ref, avatarPath) async {
  if (avatarPath == null || avatarPath.trim().isEmpty) {
    return null;
  }

  final path = avatarPath.trim();

  // If path is already a full HTTP/HTTPS URL
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  // avatars bucket is public read: resolve directly via getPublicUrl
  try {
    if (Supabase.instance.isInitialized) {
      final cleanPath = path.startsWith('avatars/') ? path.substring('avatars/'.length) : path;
      final pubUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(cleanPath);
      if (pubUrl.isNotEmpty) {
        return pubUrl;
      }
    }
  } catch (e) {
    if (kDebugMode) {
      AppLogger.w('Failed to get public URL for avatarPath="$path": $e');
    }
  }

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

  final Uint8List? imageBytes;
  final bool isLoading;

  const UserAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    this.radius = 32,
    this.backgroundColor,
    this.textColor,
    this.fallbackIcon,
    this.onTap,
    this.imageBytes,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarAsync = ref.watch(avatarUrlProvider(avatarPath));
    final initials = getInitials(name);
    final bg = backgroundColor ?? AppColors.headerGreenDark.withAlpha(38);
    final textCol = textColor ?? AppColors.headerGreenDark;

    Widget avatarWidget;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: ClipOval(
          child: Image.memory(
            imageBytes!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      avatarWidget = avatarAsync.when(
        data: (url) {
          if (url != null && url.isNotEmpty) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: bg,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => SizedBox(
                    width: radius / 2,
                    height: radius / 2,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
                    ),
                  ),
                  errorWidget: (context, _, error) {
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
    }

    if (isLoading) {
      avatarWidget = Stack(
        alignment: Alignment.center,
        children: [
          avatarWidget,
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: radius / 2,
                height: radius / 2,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

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
