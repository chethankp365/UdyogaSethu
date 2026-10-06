import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/privacy/data/consent_repository.dart';
import 'package:udyogasethu/features/privacy/domain/consent_purpose.dart';
import 'package:udyogasethu/features/privacy/presentation/consent_sheet.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class PrivacyCentreScreen extends ConsumerStatefulWidget {
  const PrivacyCentreScreen({super.key});

  @override
  ConsumerState<PrivacyCentreScreen> createState() => _PrivacyCentreScreenState();
}

class _PrivacyCentreScreenState extends ConsumerState<PrivacyCentreScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  Map<ConsentPurpose, ConsentLog?> _consents = {};

  // Live OS Permission states
  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _locationServiceEnabled = true;
  bool _notificationGranted = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOsPermissions();
      _loadConsents(silent: true);
    }
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadConsents(silent: true),
      _checkOsPermissions(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConsents({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final data = await ref.read(consentRepositoryProvider).getAllConsents();
      if (mounted) {
        setState(() {
          _consents = data;
          if (!silent) _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkOsPermissions() async {
    if (!mounted) return;
    setState(() => _isCheckingPermissions = true);

    bool camera = false;
    bool location = false;
    bool locService = true;
    bool notification = false;

    try {
      final camStatus = await Permission.camera.status.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => PermissionStatus.denied,
      );
      camera = camStatus.isGranted;
    } catch (_) {}

    try {
      locService = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => true,
      );
      final locStatus = await Permission.location.status.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => PermissionStatus.denied,
      );
      location = locStatus.isGranted && locService;
    } catch (_) {}

    try {
      final notifStatus = await Permission.notification.status.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => PermissionStatus.denied,
      );
      notification = notifStatus.isGranted;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _cameraGranted = camera;
        _locationGranted = location;
        _locationServiceEnabled = locService;
        _notificationGranted = notification;
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _handleWithdraw(ConsentPurpose purpose) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(consentRepositoryProvider);
    final details = ConsentPurposeDetails.getDetails(purpose);

    String title;
    String message;
    String confirmText;
    bool isDanger = false;

    switch (purpose) {
      case ConsentPurpose.face:
        title = l10n?.withdrawFaceConsentTitle ?? 'Withdraw Face Verification Consent?';
        message = l10n?.withdrawFaceConsentMessage ??
            'Withdrawing face consent will permanently erase your face reference vector and matcher records. You will need to re-enroll to use face-verified login.';
        confirmText = l10n?.confirmWithdrawButton ?? 'Withdraw & Erase Data';
        isDanger = true;
        break;
      case ConsentPurpose.kyc:
        title = 'Withdraw KYC Identity Consent?';
        message =
            'Withdrawing KYC consent will suspend your Verified Worker badge. Job providers will see your profile as unverified until you complete KYC again.';
        confirmText = 'Withdraw KYC';
        isDanger = true;
        break;
      case ConsentPurpose.gps:
        title = 'Withdraw GPS Location Consent?';
        message =
            'Withdrawing GPS consent prevents calculating real-time travel distance, showing live work pins on the map, and logging geofenced attendance.';
        confirmText = 'Withdraw GPS';
        break;
      case ConsentPurpose.notifications:
        title = 'Withdraw Notification Consent?';
        message =
            'You will no longer receive timely push alerts about job offers, employer check-ins, or instant wage payouts.';
        confirmText = 'Withdraw Alerts';
        break;
      case ConsentPurpose.ads:
        title = 'Withdraw Relevant Schemes Consent?';
        message =
            'You will receive general announcements instead of personalised government welfare schemes and local district training programs.';
        confirmText = 'Withdraw Scheme Consent';
        break;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.cancelButton ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.errorRed : AppColors.darkOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (purpose == ConsentPurpose.face) {
        await repo.withdrawFaceConsent();
      } else {
        await repo.revokeConsent(purpose);
      }
      await _loadConsents(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${details.title} consent withdrawn and logged to audit records.'),
            backgroundColor: AppColors.textDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.privacyCentreTitle ?? 'Privacy Centre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: l10n?.refreshConsentsTooltip ?? 'Refresh Status',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
          ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.headerGreenDark))
          : RefreshIndicator(
              color: AppColors.headerGreenDark,
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header DPDP Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.headerGreenDark.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.headerGreenDark.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.privacy_tip_rounded, color: AppColors.headerGreenDark, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.privacyCentreTitle ?? 'Privacy Centre',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n?.privacyCentreSubtitle ??
                                      'Manage your data consents, privacy rights, and system permissions in accordance with DPDP rules.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Active Data Consents
                    const Text(
                      'Active Data Consents',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),

                    ...ConsentPurpose.values.map((purpose) {
                      final log = _consents[purpose];
                      final isGranted = log?.granted ?? false;
                      final details = ConsentPurposeDetails.getDetails(purpose);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(details.icon, color: isGranted ? AppColors.headerGreenDark : AppColors.textMuted),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      details.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isGranted ? Colors.green.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isGranted ? Colors.green.shade300 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                          size: 13,
                                          color: isGranted ? Colors.green.shade800 : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isGranted
                                              ? (l10n?.consentGrantedStatus ?? 'Consent Granted')
                                              : (l10n?.consentRevokedStatus ?? 'Not Granted / Withdrawn'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isGranted ? Colors.green.shade800 : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                details.why,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              if (log?.timestamp != null && isGranted) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Granted on: ${log!.timestamp.toLocal().toString().split('.').first}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      final res = await ConsentSheet.show(context, purpose);
                                      if (res == true) {
                                        await _loadConsents(silent: true);
                                      }
                                    },
                                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                                    label: const Text('View Terms', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isGranted)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.errorRed,
                                        side: const BorderSide(color: AppColors.errorRed),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () => _handleWithdraw(purpose),
                                      icon: const Icon(Icons.block_rounded, size: 16),
                                      label: Text(
                                        l10n?.withdrawConsentButton ?? 'Withdraw Consent',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Section: System Permissions (Live OS Reflection)
                    Row(
                      children: [
                        Text(
                          l10n?.systemPermissionsTitle ?? 'System Permissions',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(width: 8),
                        if (_isCheckingPermissions)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.headerGreenDark),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Live hardware permissions enabled on your device.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),

                    // Camera Permission Card
                    _buildPermissionCard(
                      icon: Icons.camera_alt_rounded,
                      title: l10n?.cameraPermissionTitle ?? 'Camera Access',
                      subtitle: l10n?.cameraPermissionSubtitle ?? 'Used for face liveness verification and worker ID scanning.',
                      isGranted: _cameraGranted,
                      allowedLabel: l10n?.permissionAllowedStatus ?? 'Allowed',
                      blockedLabel: l10n?.permissionBlockedStatus ?? 'Blocked / Off',
                      onTap: () async {
                        if (!_cameraGranted) {
                          try {
                            final res = await Permission.camera.request();
                            if (res.isPermanentlyDenied) {
                              await openAppSettings();
                            }
                          } catch (_) {
                            await openAppSettings();
                          }
                          await _checkOsPermissions();
                        } else {
                          await openAppSettings();
                        }
                      },
                    ),

                    // Location Permission Card
                    _buildPermissionCard(
                      icon: Icons.location_on_rounded,
                      title: l10n?.locationPermissionTitle ?? 'Device Location (GPS)',
                      subtitle: !_locationServiceEnabled
                          ? 'GPS sensor is turned off on device. Tap to enable.'
                          : (l10n?.locationPermissionSubtitle ??
                              'Used to show nearby jobs, job route map, and work site attendance.'),
                      isGranted: _locationGranted,
                      allowedLabel: l10n?.permissionAllowedStatus ?? 'Allowed',
                      blockedLabel: !_locationServiceEnabled ? 'GPS Off' : (l10n?.permissionBlockedStatus ?? 'Blocked / Off'),
                      onTap: () async {
                        if (!_locationServiceEnabled) {
                          try {
                            await Geolocator.openLocationSettings();
                          } catch (_) {
                            await openAppSettings();
                          }
                        } else if (!_locationGranted) {
                          try {
                            final res = await Permission.location.request();
                            if (res.isPermanentlyDenied) {
                              await openAppSettings();
                            }
                          } catch (_) {
                            await openAppSettings();
                          }
                        } else {
                          await openAppSettings();
                        }
                        await _checkOsPermissions();
                      },
                    ),

                    // Notifications Permission Card
                    _buildPermissionCard(
                      icon: Icons.notifications_active_rounded,
                      title: l10n?.notificationPermissionTitle ?? 'Notifications',
                      subtitle: l10n?.notificationPermissionSubtitle ??
                          'Used for instant job alerts, payment updates, and safety alerts.',
                      isGranted: _notificationGranted,
                      allowedLabel: l10n?.permissionAllowedStatus ?? 'Allowed',
                      blockedLabel: l10n?.permissionBlockedStatus ?? 'Blocked / Off',
                      onTap: () async {
                        if (!_notificationGranted) {
                          try {
                            final res = await Permission.notification.request();
                            if (res.isPermanentlyDenied) {
                              await openAppSettings();
                            }
                          } catch (_) {
                            await openAppSettings();
                          }
                          await _checkOsPermissions();
                        } else {
                          await openAppSettings();
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    // Open Native Settings Card
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.settings_suggest_rounded, color: AppColors.headerGreenDark),
                        title: Text(l10n?.openSystemSettings ?? 'Open App Settings'),
                        subtitle: const Text(
                          'Configure system permission toggles directly in phone settings.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => openAppSettings(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required String allowedLabel,
    required String blockedLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: isGranted ? AppColors.headerGreenDark : AppColors.textMuted, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGranted ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isGranted ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 12,
                      color: isGranted ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGranted ? allowedLabel : blockedLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isGranted ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
