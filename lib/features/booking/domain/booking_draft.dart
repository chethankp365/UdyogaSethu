import 'user_address.dart';

/// State of a direct booking in progress through the guided sequence:
/// Step 0: Service
/// Step 1: Worker
/// Step 2: Date & Time
/// Step 3: Address
/// Step 4: Review Price
/// Step 5: Payment
/// Step 6: Confirm (Unverified Notice or Pass Ticket)
class BookingDraft {
  final String workerId;
  final String workerName;
  final String? workerAvatar;
  final double workerRating;
  final int workerJobsCount;
  final bool isWorkerVerified;
  final String? categoryId;
  final String categoryName;
  final int dailyRatePaise;
  final int hourlyRatePaise;

  final String title;
  final String notes;
  final int durationMinutes; // 240 (half day), 480 (full day), or custom

  final DateTime selectedDate;
  final int selectedTimeHour;
  final int selectedTimeMinute;

  final UserAddress? selectedAddress;
  final String manualAddressText;
  final double? lat;
  final double? lng;

  final int wagePaise;
  final int platformFeePaise; // Defaults to 4500 paise = ₹45
  final int protectionCoverPaise; // 4000 paise = ₹40
  final bool isProtectionSelected;

  final int? minFairWagePaise;
  final int? maxFairWagePaise;

  final String paymentMode; // 'escrow', 'cash', 'upi'
  final bool isRecurring;
  final String recurringRule; // 'weekly', 'monthly'
  final String? recurringTime;

  final int currentStep;

  const BookingDraft({
    required this.workerId,
    required this.workerName,
    this.workerAvatar,
    this.workerRating = 4.8,
    this.workerJobsCount = 24,
    this.isWorkerVerified = true,
    this.categoryId,
    required this.categoryName,
    this.dailyRatePaise = 85000,
    this.hourlyRatePaise = 15000,
    this.title = '',
    this.notes = '',
    this.durationMinutes = 480, // Default 8 hours
    required this.selectedDate,
    this.selectedTimeHour = 9,
    this.selectedTimeMinute = 0,
    this.selectedAddress,
    this.manualAddressText = '',
    this.lat,
    this.lng,
    this.wagePaise = 85000,
    this.platformFeePaise = 4500,
    this.protectionCoverPaise = 4000,
    this.isProtectionSelected = false,
    this.minFairWagePaise = 70000,
    this.maxFairWagePaise = 100000,
    this.paymentMode = 'escrow',
    this.isRecurring = false,
    this.recurringRule = 'weekly',
    this.recurringTime,
    this.currentStep = 0,
  });

  DateTime get startAt {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTimeHour,
      selectedTimeMinute,
    );
  }

  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));

  int get totalPaise {
    return wagePaise + platformFeePaise + (isProtectionSelected ? protectionCoverPaise : 0);
  }

  String get formattedWage => '₹${(wagePaise / 100).toStringAsFixed(0)}';
  String get formattedPlatformFee => '₹${(platformFeePaise / 100).toStringAsFixed(0)}';
  String get formattedProtectionCover => '₹${(protectionCoverPaise / 100).toStringAsFixed(0)}';
  String get formattedTotal => '₹${(totalPaise / 100).toStringAsFixed(0)}';

  bool get isBelowFairWage => minFairWagePaise != null && wagePaise < minFairWagePaise!;
  bool get isAboveFairWage => maxFairWagePaise != null && wagePaise > maxFairWagePaise!;

  String get effectiveAddressText {
    if (selectedAddress != null) {
      return selectedAddress!.formattedAddress;
    }
    return manualAddressText.isNotEmpty ? manualAddressText : 'Bengaluru, Karnataka';
  }

  double? get effectiveLat => selectedAddress?.lat ?? lat;
  double? get effectiveLng => selectedAddress?.lng ?? lng;

  BookingDraft copyWith({
    String? workerId,
    String? workerName,
    String? workerAvatar,
    double? workerRating,
    int? workerJobsCount,
    bool? isWorkerVerified,
    String? categoryId,
    String? categoryName,
    int? dailyRatePaise,
    int? hourlyRatePaise,
    String? title,
    String? notes,
    int? durationMinutes,
    DateTime? selectedDate,
    int? selectedTimeHour,
    int? selectedTimeMinute,
    UserAddress? selectedAddress,
    bool clearSelectedAddress = false,
    String? manualAddressText,
    double? lat,
    double? lng,
    int? wagePaise,
    int? platformFeePaise,
    int? protectionCoverPaise,
    bool? isProtectionSelected,
    int? minFairWagePaise,
    int? maxFairWagePaise,
    String? paymentMode,
    bool? isRecurring,
    String? recurringRule,
    String? recurringTime,
    int? currentStep,
  }) {
    return BookingDraft(
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerAvatar: workerAvatar ?? this.workerAvatar,
      workerRating: workerRating ?? this.workerRating,
      workerJobsCount: workerJobsCount ?? this.workerJobsCount,
      isWorkerVerified: isWorkerVerified ?? this.isWorkerVerified,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      dailyRatePaise: dailyRatePaise ?? this.dailyRatePaise,
      hourlyRatePaise: hourlyRatePaise ?? this.hourlyRatePaise,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeHour: selectedTimeHour ?? this.selectedTimeHour,
      selectedTimeMinute: selectedTimeMinute ?? this.selectedTimeMinute,
      selectedAddress: clearSelectedAddress ? null : (selectedAddress ?? this.selectedAddress),
      manualAddressText: manualAddressText ?? this.manualAddressText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      wagePaise: wagePaise ?? this.wagePaise,
      platformFeePaise: platformFeePaise ?? this.platformFeePaise,
      protectionCoverPaise: protectionCoverPaise ?? this.protectionCoverPaise,
      isProtectionSelected: isProtectionSelected ?? this.isProtectionSelected,
      minFairWagePaise: minFairWagePaise ?? this.minFairWagePaise,
      maxFairWagePaise: maxFairWagePaise ?? this.maxFairWagePaise,
      paymentMode: paymentMode ?? this.paymentMode,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRule: recurringRule ?? this.recurringRule,
      recurringTime: recurringTime ?? this.recurringTime,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
