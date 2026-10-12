import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/booking/data/booking_repository.dart';
import 'package:udyogasethu/features/booking/domain/booked_slot.dart';
import 'package:udyogasethu/features/booking/domain/booking_draft.dart';
import 'package:udyogasethu/features/booking/domain/booking_result.dart';
import 'package:udyogasethu/features/booking/domain/user_address.dart';
import 'package:udyogasethu/features/booking/presentation/booking_controller.dart';
import 'package:udyogasethu/features/matching/data/recommendation_pricing_service.dart';
import 'package:udyogasethu/features/matching/presentation/widgets/fair_wage_card.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

/// 7-step guided direct booking sequence:
/// Step 0: Service (title, notes, duration, recurring option)
/// Step 1: Worker (worker details, rates, verification badge)
/// Step 2: Date and Time (calendar date, slot picker with conflict prevention)
/// Step 3: Address (saved addresses or new address with OpenStreetMap pin)
/// Step 4: Review Price (wage, platform fee preview, fair-wage indicator, total)
/// Step 5: Payment (placeholder selector for cash, upi, escrow)
/// Step 6: Confirm (Unverified worker dark-panel notice or Verified confirmation -> Booking Pass Ticket)
class GuidedBookingScreen extends ConsumerStatefulWidget {
  final BookingDraft? initialDraft;

  const GuidedBookingScreen({
    super.key,
    this.initialDraft,
  });

  @override
  ConsumerState<GuidedBookingScreen> createState() => _GuidedBookingScreenState();
}

class _GuidedBookingScreenState extends ConsumerState<GuidedBookingScreen> {
  late BookingDraft _draft;

  // Controllers for Service step
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  // Controller for Price step
  late final TextEditingController _wageController;

  // Controllers for new address
  late final TextEditingController _addressLabelController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;

  bool _isAddingNewAddress = false;
  bool _saveAsDefaultAddress = false;
  LatLng _selectedPin = const LatLng(12.9716, 77.5946); // Bengaluru default
  final MapController _mapController = MapController();

  BookingResult? _submittedResult;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ??
        BookingDraft(
          workerId: 'worker-sample',
          workerName: 'Ramesh Kumar',
          categoryName: 'Electrician',
          isWorkerVerified: true,
          dailyRatePaise: 85000,
          hourlyRatePaise: 15000,
          wagePaise: 85000,
          selectedDate: DateTime.now().add(const Duration(days: 1)),
        );

    _titleController = TextEditingController(text: _draft.title.isNotEmpty ? _draft.title : '${_draft.categoryName} Service');
    _notesController = TextEditingController(text: _draft.notes);
    _wageController = TextEditingController(text: (_draft.wagePaise / 100).toStringAsFixed(0));

    _addressLabelController = TextEditingController(text: 'Home');
    _addressLine1Controller = TextEditingController();
    _landmarkController = TextEditingController();
    _cityController = TextEditingController(text: 'Bengaluru');
    _pincodeController = TextEditingController(text: '560034');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _wageController.dispose();
    _addressLabelController.dispose();
    _addressLine1Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submissionState = ref.watch(bookingSubmissionProvider);

    // If booking was submitted successfully, show the Booking Pass Ticket!
    if (_submittedResult != null) {
      return _buildBookingPassTicketScreen(context, l10n, _submittedResult!);
    }

    // Step 6 for an unverified worker renders the Old Dark-Panel "Not UdyogaSethu Verified" screen
    if (_draft.currentStep == 6 && !_draft.isWorkerVerified) {
      return _buildUnverifiedWorkerDarkNotice(context, l10n, submissionState);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingWizardTitle),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_draft.currentStep > 0) {
              setState(() {
                _draft = _draft.copyWith(currentStep: _draft.currentStep - 1);
              });
            } else {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.providerHome);
              }
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(context, l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(context, l10n),
              ),
            ),
            _buildBottomActionBar(context, l10n, submissionState),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP INDICATOR (Service, Worker, Date/Time, Address, Price, Payment, Confirm)
  // -------------------------------------------------------------
  Widget _buildStepIndicator(BuildContext context, AppLocalizations l10n) {
    final stepTitles = [
      l10n.bookingStepService,
      'Worker',
      l10n.bookingStepDateTime,
      l10n.bookingStepAddress,
      'Price',
      'Payment',
      'Confirm',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(stepTitles.length, (index) {
            final isCompleted = _draft.currentStep > index;
            final isCurrent = _draft.currentStep == index;

            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (index < _draft.currentStep) {
                      setState(() {
                        _draft = _draft.copyWith(currentStep: index);
                      });
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isCompleted
                            ? AppColors.headerGreenDark
                            : isCurrent
                                ? AppColors.amberOrange
                                : Colors.grey.shade300,
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stepTitles[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.amberOrange
                              : isCompleted
                                  ? AppColors.headerGreenDark
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < stepTitles.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 14,
                      height: 2,
                      color: isCompleted ? AppColors.headerGreenDark : Colors.grey.shade300,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // CURRENT STEP CONTENT SWITCHER
  // -------------------------------------------------------------
  Widget _buildStepContent(BuildContext context, AppLocalizations l10n) {
    switch (_draft.currentStep) {
      case 0:
        return _buildStepService(context, l10n);
      case 1:
        return _buildStepWorker(context, l10n);
      case 2:
        return _buildStepDateTime(context, l10n);
      case 3:
        return _buildStepAddress(context, l10n);
      case 4:
        return _buildStepPrice(context, l10n);
      case 5:
        return _buildStepPayment(context, l10n);
      case 6:
        return _buildStepVerifiedConfirm(context, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------
  // STEP 0: Service (Title, Notes, Duration, Recurring)
  // -------------------------------------------------------------
  Widget _buildStepService(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingServiceTitleLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: l10n.bookingServiceTitleHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (v) => _draft = _draft.copyWith(title: v),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.bookingDuration,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: l10n.bookingDurationHalfDay,
                isSelected: _draft.durationMinutes == 240,
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(durationMinutes: 240);
                    if (_draft.hourlyRatePaise > 0) {
                      final calc = _draft.hourlyRatePaise * 4;
                      _wageController.text = (calc / 100).toStringAsFixed(0);
                      _draft = _draft.copyWith(wagePaise: calc);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: l10n.bookingDurationFullDay,
                isSelected: _draft.durationMinutes == 480,
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(durationMinutes: 480);
                    if (_draft.dailyRatePaise > 0) {
                      _wageController.text = (_draft.dailyRatePaise / 100).toStringAsFixed(0);
                      _draft = _draft.copyWith(wagePaise: _draft.dailyRatePaise);
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.bookingSpecialNotes,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.bookingSpecialNotesHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (v) => _draft = _draft.copyWith(notes: v),
        ),
        const SizedBox(height: 20),
        // Recurring schedule toggle
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.repeat, color: AppColors.headerGreenDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.bookingRecurringOption,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: _draft.isRecurring,
                      activeTrackColor: AppColors.headerGreenDark,
                      onChanged: (val) {
                        setState(() {
                          _draft = _draft.copyWith(isRecurring: val);
                        });
                      },
                    ),
                  ],
                ),
                Text(
                  l10n.bookingRecurringToggle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (_draft.isRecurring) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.bookingRecurringWeekly),
                        selected: _draft.recurringRule == 'weekly',
                        onSelected: (sel) {
                          if (sel) setState(() => _draft = _draft.copyWith(recurringRule: 'weekly'));
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(l10n.bookingRecurringMonthly),
                        selected: _draft.recurringRule == 'monthly',
                        onSelected: (sel) {
                          if (sel) setState(() => _draft = _draft.copyWith(recurringRule: 'monthly'));
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 1: Worker Details & Rates
  // -------------------------------------------------------------
  Widget _buildStepWorker(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.headerGreenDark.withValues(alpha: 0.1),
                      backgroundImage: _draft.workerAvatar != null ? NetworkImage(_draft.workerAvatar!) : null,
                      child: _draft.workerAvatar == null
                          ? Text(
                              _draft.workerName.isNotEmpty ? _draft.workerName[0].toUpperCase() : 'W',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _draft.workerName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _draft.categoryName,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${_draft.workerRating} (${_draft.workerJobsCount} jobs)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Daily Rate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${(_draft.dailyRatePaise / 100).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        Text('Hourly Rate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${(_draft.hourlyRatePaise / 100).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Trust and Verification status notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _draft.isWorkerVerified ? Colors.green.shade50 : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _draft.isWorkerVerified ? Colors.green.shade300 : Colors.amber.shade400,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _draft.isWorkerVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: _draft.isWorkerVerified ? Colors.green.shade700 : Colors.amber.shade900,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _draft.isWorkerVerified ? 'UdyogaSethu Verified Worker' : l10n.bookingUnverifiedNoticeTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _draft.isWorkerVerified ? Colors.green.shade900 : Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _draft.isWorkerVerified
                          ? 'Aadhaar eKYC verified with completed safety training.'
                          : l10n.bookingUnverifiedNoticeSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _draft.isWorkerVerified ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: Date and Time (Available vs Booked Conflict Prevention)
  // -------------------------------------------------------------
  Widget _buildStepDateTime(BuildContext context, AppLocalizations l10n) {
    final bookedSlotsAsync = ref.watch(workerBookedSlotsProvider(_draft.workerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingSelectDate,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        // 14-day horizontal date selector
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = _draft.selectedDate.year == date.year &&
                  _draft.selectedDate.month == date.month &&
                  _draft.selectedDate.day == date.day;

              final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

              return InkWell(
                onTap: () {
                  setState(() {
                    _draft = _draft.copyWith(selectedDate: date);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.headerGreenDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekday,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.bookingSelectTimeSlot,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        // Slots with Conflict Detection
        bookedSlotsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (_, _) => _buildSlotChips(const []),
          data: (slots) => _buildSlotChips(slots),
        ),
      ],
    );
  }

  Widget _buildSlotChips(List<BookedSlot> slots) {
    final l10n = AppLocalizations.of(context)!;
    // Standard daily slots (Hour, Minute, Display)
    final candidateSlots = [
      (8, 0, '08:00 AM'),
      (10, 0, '10:00 AM'),
      (13, 0, '01:00 PM'),
      (15, 0, '03:00 PM'),
      (17, 0, '05:00 PM'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: candidateSlots.map((slot) {
            final slotStart = DateTime(
              _draft.selectedDate.year,
              _draft.selectedDate.month,
              _draft.selectedDate.day,
              slot.$1,
              slot.$2,
            );

            // Check if worker already has a booked assignment overlapping this window
            final isBooked = slots.any((s) => s.overlapsWith(slotStart, _draft.durationMinutes));
            final isSelected = _draft.selectedTimeHour == slot.$1 && _draft.selectedTimeMinute == slot.$2;

            return InkWell(
              onTap: isBooked
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.bookingScheduleConflictAlert),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  : () {
                      setState(() {
                        _draft = _draft.copyWith(
                          selectedTimeHour: slot.$1,
                          selectedTimeMinute: slot.$2,
                        );
                      });
                    },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isBooked
                      ? Colors.grey.shade100
                      : isSelected
                          ? AppColors.headerGreenDark
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBooked
                        ? Colors.grey.shade300
                        : isSelected
                            ? AppColors.headerGreenDark
                            : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBooked ? Icons.lock_clock_rounded : Icons.access_time_rounded,
                      size: 16,
                      color: isBooked
                          ? Colors.grey
                          : isSelected
                              ? Colors.white
                              : AppColors.headerGreenDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      slot.$3,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isBooked
                            ? Colors.grey.shade500
                            : isSelected
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.red.shade50
                            : isSelected
                                ? Colors.white24
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBooked ? l10n.bookingSlotBooked : l10n.bookingSlotAvailable,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isBooked
                              ? Colors.red.shade700
                              : isSelected
                                  ? Colors.white
                                  : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(l10n.bookingSlotAvailable, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(width: 14),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(l10n.bookingSlotBooked, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 3: Address (Saved or New Address with Map Pin)
  // -------------------------------------------------------------
  Widget _buildStepAddress(BuildContext context, AppLocalizations l10n) {
    final addressesAsync = ref.watch(savedAddressesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingAddressTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (!_isAddingNewAddress) ...[
          addressesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (_, _) => _buildFallbackAddressSelection(),
            data: (addresses) {
              if (addresses.isEmpty) return _buildFallbackAddressSelection();
              return Column(
                children: [
                  ...addresses.map((addr) {
                    final isSelected = _draft.selectedAddress?.id == addr.id ||
                        (_draft.selectedAddress == null && addr.isDefault);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _draft = _draft.copyWith(
                              selectedAddress: addr,
                              manualAddressText: addr.formattedAddress,
                              lat: addr.lat,
                              lng: addr.lng,
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.paleMint : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(addr.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(addr.formattedAddress, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.headerGreenDark,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: Text(l10n.bookingAddNewAddress),
                    onPressed: () {
                      setState(() {
                        _isAddingNewAddress = true;
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ] else ...[
          // Adding new address form with OpenStreetMap pin placement
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.bookingAddNewAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _isAddingNewAddress = false),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _addressLabelController,
                    decoration: InputDecoration(
                      labelText: l10n.bookingAddressLabel,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressLine1Controller,
                    decoration: InputDecoration(
                      labelText: l10n.bookingAddressLine1,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      labelText: l10n.bookingLandmark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: l10n.bookingCity,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.bookingPincode,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Map Pin Placement (Tap to adjust):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPin,
                        initialZoom: 14.0,
                        onTap: (_, point) {
                          setState(() {
                            _selectedPin = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'in.udyogasethu',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPin,
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.location_on, size: 36, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: _saveAsDefaultAddress,
                    onChanged: (val) => setState(() => _saveAsDefaultAddress = val ?? false),
                    title: Text(l10n.bookingSaveAsDefault, style: const TextStyle(fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreenDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () async {
                      if (_addressLine1Controller.text.trim().isEmpty) return;
                      final addr = UserAddress(
                        id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                        userId: '',
                        label: _addressLabelController.text.trim(),
                        line1: _addressLine1Controller.text.trim(),
                        landmark: _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : null,
                        city: _cityController.text.trim(),
                        pincode: _pincodeController.text.trim(),
                        lat: _selectedPin.latitude,
                        lng: _selectedPin.longitude,
                        isDefault: _saveAsDefaultAddress,
                      );
                      await ref.read(bookingRepositoryProvider).saveAddress(addr);
                      ref.invalidate(savedAddressesProvider);
                      setState(() {
                        _draft = _draft.copyWith(
                          selectedAddress: addr,
                          manualAddressText: addr.formattedAddress,
                          lat: addr.lat,
                          lng: addr.lng,
                        );
                        _isAddingNewAddress = false;
                      });
                    },
                    child: const Text('Save & Select Address'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackAddressSelection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected Service Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(_draft.effectiveAddressText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() => _isAddingNewAddress = true),
              child: const Text('Add Address with Map Pin'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 4: Review Price (Wage, Platform Fee, Fair-Wage Indicator, Total)
  // -------------------------------------------------------------
  Widget _buildStepPrice(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingPriceBreakdown,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Wage Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.bookingAgreedWage, style: const TextStyle(fontSize: 14)),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _wageController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final numVal = int.tryParse(v) ?? 0;
                          setState(() {
                            _draft = _draft.copyWith(wagePaise: numVal * 100);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Platform fee
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.bookingPlatformFee, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    Text(_draft.formattedPlatformFee, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (_draft.isProtectionSelected) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(l10n.bookingProtectionCoverFee, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(l10n.demoModeBadge, style: TextStyle(fontSize: 10, color: Colors.amber.shade900)),
                          ),
                        ],
                      ),
                      Text(_draft.formattedProtectionCover, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const Divider(height: 24),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.bookingTotalPrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      _draft.formattedTotal,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Fair Wage Suggestion Card
        FairWageCard(
          suggestion: ref.watch(recommendationPricingServiceProvider).calculateWageSuggestion(
                benchmarkMinPaise: 70000,
                benchmarkMaxPaise: 100000,
                unit: 'day',
                yearsOfExperience: 3,
                isUrgent: false,
                isHighDemand: true,
              ),
          offeredWagePaise: _draft.wagePaise,
          onApplySuggested: () {
            setState(() {
              _draft = _draft.copyWith(wagePaise: 70000);
              _wageController.text = '700';
            });
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 5: Payment (Placeholder Selector until P5.2)
  // -------------------------------------------------------------
  Widget _buildStepPayment(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingPaymentMethod,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionCard(
          title: l10n.bookingPaymentEscrow,
          subtitle: 'Funds held securely and released after verified job completion.',
          icon: Icons.shield_rounded,
          isSelected: _draft.paymentMode == 'escrow',
          onTap: () => setState(() => _draft = _draft.copyWith(paymentMode: 'escrow')),
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionCard(
          title: l10n.bookingPaymentCash,
          subtitle: 'Pay cash directly to the worker at work site.',
          icon: Icons.payments_outlined,
          isSelected: _draft.paymentMode == 'cash',
          onTap: () => setState(() => _draft = _draft.copyWith(paymentMode: 'cash')),
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionCard(
          title: l10n.bookingPaymentUpi,
          subtitle: 'Instant UPI payment upon QR check-in.',
          icon: Icons.qr_code_scanner_rounded,
          isSelected: _draft.paymentMode == 'upi',
          onTap: () => setState(() => _draft = _draft.copyWith(paymentMode: 'upi')),
        ),
        const SizedBox(height: 16),
        // Placeholder banner until P5.2
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.amberOrange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bookingPaymentPlaceholder,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Payment mode selection is stored in payment_mode. Razorpay test integration opens in Phase 5.2.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paleMint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade600, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppColors.headerGreenDark : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.headerGreenDark, size: 20),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 6 (VERIFIED WORKER): Summary & Confirm
  // -------------------------------------------------------------
  Widget _buildStepVerifiedConfirm(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: AppColors.headerGreenDark, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verified Worker — Notice Skipped', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Worker has verified credentials. Proceeding directly to confirmation pass.', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildBookingSummaryCard(context, l10n),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 6 (UNVERIFIED WORKER): Old Dark-Panel "Not UdyogaSethu Verified"
  // -------------------------------------------------------------
  Widget _buildUnverifiedWorkerDarkNotice(BuildContext context, AppLocalizations l10n, AsyncValue<BookingResult?> submissionState) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: Text(l10n.bookingUnverifiedNoticeTitle),
        backgroundColor: const Color(0xFF0B132B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _draft = _draft.copyWith(currentStep: 5);
            });
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.amberOrange, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.bookingUnverifiedNoticeTitle,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.bookingUnverifiedNoticeSubtitle,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.amberOrange),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.bookingUnverifiedNoticeDesc,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Option 1: Add ₹40 Job Protection Cover (Demo mode)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _draft = _draft.copyWith(isProtectionSelected: true);
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _draft.isProtectionSelected ? const Color(0xFF10B981) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _draft.isProtectionSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: _draft.isProtectionSelected ? const Color(0xFF10B981) : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          l10n.bookingProtectionCoverTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade900.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber),
                                          ),
                                          child: Text(
                                            l10n.demoModeBadge,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.bookingProtectionCoverDesc,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Option 2: Book without protection
                      InkWell(
                        onTap: () {
                          setState(() {
                            _draft = _draft.copyWith(isProtectionSelected: false);
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_draft.isProtectionSelected ? const Color(0xFF10B981) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                !_draft.isProtectionSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: !_draft.isProtectionSelected ? const Color(0xFF10B981) : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.bookingBookWithoutProtection,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.bookingBookWithoutProtectionDesc,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Total calculation preview
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132238),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Updated Total:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                            Text(
                              _draft.formattedTotal,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Confirm button on dark panel
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: submissionState.isLoading ? null : () => _submitBookingAndShowTicket(),
                child: submissionState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        l10n.bookingProceedToTicket,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Service', _draft.title.isNotEmpty ? _draft.title : '${_draft.categoryName} Service'),
            const Divider(),
            _buildSummaryRow('Worker', _draft.workerName),
            const Divider(),
            _buildSummaryRow('Date & Time', '${_draft.selectedDate.day}/${_draft.selectedDate.month} at ${_draft.selectedTimeHour.toString().padLeft(2, '0')}:${_draft.selectedTimeMinute.toString().padLeft(2, '0')}'),
            const Divider(),
            _buildSummaryRow('Address', _draft.effectiveAddressText),
            const Divider(),
            _buildSummaryRow('Payment Mode', _draft.paymentMode.toUpperCase()),
            const Divider(),
            _buildSummaryRow('Total', _draft.formattedTotal, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: isBold ? 15 : 13),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM ACTION BAR
  // -------------------------------------------------------------
  Widget _buildBottomActionBar(BuildContext context, AppLocalizations l10n, AsyncValue<BookingResult?> submissionState) {
    final isLastStep = _draft.currentStep == 6;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_draft.currentStep > 0) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.headerGreenDark,
                minimumSize: const Size(80, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _draft = _draft.copyWith(currentStep: _draft.currentStep - 1);
                });
              },
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerGreenDark,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: submissionState.isLoading
                  ? null
                  : () {
                      if (isLastStep) {
                        _submitBookingAndShowTicket();
                      } else {
                        setState(() {
                          _draft = _draft.copyWith(currentStep: _draft.currentStep + 1);
                        });
                      }
                    },
              child: submissionState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isLastStep ? l10n.bookingProceedToTicket : 'Next Step',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SUBMISSION & TICKET SCREEN
  // -------------------------------------------------------------
  Future<void> _submitBookingAndShowTicket() async {
    final result = await ref.read(bookingSubmissionProvider.notifier).submit(_draft);
    if (result != null) {
      setState(() {
        _submittedResult = result;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit booking. Worker may already be booked for this slot.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBookingPassTicketScreen(BuildContext context, AppLocalizations l10n, BookingResult result) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(l10n.bookingTicketTitle),
        backgroundColor: AppColors.headerGreenDark,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Ticket Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade400),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.bookingStatusWaiting,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${l10n.bookingCodeLabel}: ${result.bookingCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.headerGreenDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _draft.title.isNotEmpty ? _draft.title : '${_draft.categoryName} Service',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Worker: ${_draft.workerName}',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.headerGreenDark),
                              const SizedBox(width: 6),
                              Text(
                                '${_draft.selectedDate.day}/${_draft.selectedDate.month}/${_draft.selectedDate.year} at ${_draft.selectedTimeHour.toString().padLeft(2, '0')}:${_draft.selectedTimeMinute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Perforated line with semi-circles
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  (constraints.constrainWidth() / 10).floor(),
                                  (_) => const SizedBox(
                                    width: 5,
                                    height: 1.5,
                                    child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _draft.effectiveAddressText,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Mode:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              Text(_draft.paymentMode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Agreed:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              Text(
                                _draft.formattedTotal,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.headerGreenDark),
                              ),
                            ],
                          ),
                          if (result.protectionSelected) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield, color: AppColors.headerGreenDark, size: 16),
                                  const SizedBox(width: 6),
                                  const Text('Job Protection Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headerGreenDark)),
                                  const Spacer(),
                                  Text(l10n.demoModeBadge, style: TextStyle(fontSize: 10, color: Colors.amber.shade900)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.bookingSuccessMessage,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGreenDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.work_outline),
                label: Text(l10n.bookingViewMyJobs),
                onPressed: () => context.go(AppRoutes.providerHome),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go(AppRoutes.providerHome),
                child: Text(l10n.bookingReturnHome),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerGreenDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.headerGreenDark : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
