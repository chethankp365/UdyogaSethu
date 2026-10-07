import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/features/booking/data/booking_repository.dart';
import 'package:udyogasethu/features/booking/domain/booked_slot.dart';
import 'package:udyogasethu/features/booking/domain/booking_draft.dart';
import 'package:udyogasethu/features/booking/domain/booking_result.dart';
import 'package:udyogasethu/features/booking/domain/recurring_booking.dart';
import 'package:udyogasethu/features/booking/domain/user_address.dart';
import 'package:udyogasethu/features/booking/presentation/guided_booking_screen.dart';
import 'package:udyogasethu/features/booking/presentation/recurring_bookings_screen.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockBookingRepository implements BookingRepository {
  List<RecurringBooking> recurringBookings;
  List<BookedSlot> bookedSlots;
  List<UserAddress> addresses;
  BookingDraft? lastSubmittedDraft;

  MockBookingRepository({
    List<RecurringBooking>? initialRecurring,
    List<BookedSlot>? initialSlots,
    List<UserAddress>? initialAddresses,
  })  : recurringBookings = initialRecurring ?? _defaultRecurring(),
        bookedSlots = initialSlots ?? _defaultSlots(),
        addresses = initialAddresses ?? _defaultAddresses();

  static List<RecurringBooking> _defaultRecurring() {
    return [
      RecurringBooking(
        id: 'rec-1',
        providerId: 'prov-1',
        workerId: 'worker-101',
        workerName: 'Chethan Kumar',
        workerAvatar: null,
        categoryId: 'cat-electrician',
        categoryName: 'Electrician',
        scheduleRule: 'weekly',
        preferredTime: '09:00:00',
        status: 'active',
        skipDates: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  static List<BookedSlot> _defaultSlots() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return [
      BookedSlot(
        assignmentId: 'asgn-existing-1',
        jobId: 'job-existing-1',
        startAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
        endAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0),
        status: 'accepted',
      ),
    ];
  }

  static List<UserAddress> _defaultAddresses() {
    return const [
      UserAddress(
        id: 'addr-1',
        userId: 'user-demo',
        label: 'Home',
        line1: 'Flat 402, Green Glen Layout',
        landmark: 'Near Bellandur Lake',
        city: 'Bengaluru',
        pincode: '560103',
        lat: 12.9260,
        lng: 77.6762,
        isDefault: true,
      ),
    ];
  }

  @override
  Future<List<BookedSlot>> fetchWorkerBookedSlots(String workerId, DateTime startDate, DateTime endDate) async {
    return bookedSlots;
  }

  @override
  Future<List<UserAddress>> fetchSavedAddresses() async {
    return addresses;
  }

  @override
  Future<UserAddress> saveAddress(UserAddress address) async {
    addresses.add(address);
    return address;
  }

  @override
  Future<BookingResult> submitDirectBooking(BookingDraft draft) async {
    lastSubmittedDraft = draft;
    return BookingResult(
      assignmentId: 'asgn-test-123',
      jobId: 'job-test-123',
      bookingCode: 'BOOK-TEST1',
      status: 'requested',
      protectionSelected: draft.isProtectionSelected,
      startAt: draft.startAt,
      recurringId: draft.isRecurring ? 'rec-new-1' : null,
    );
  }

  @override
  Future<List<RecurringBooking>> fetchRecurringBookings() async {
    return recurringBookings;
  }

  @override
  Future<bool> updateRecurringBooking(String id, {String? status, String? scheduleRule, String? preferredTime}) async {
    final index = recurringBookings.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final old = recurringBookings[index];
      recurringBookings[index] = RecurringBooking(
        id: old.id,
        providerId: old.providerId,
        workerId: old.workerId,
        workerName: old.workerName,
        workerAvatar: old.workerAvatar,
        categoryId: old.categoryId,
        categoryName: old.categoryName,
        scheduleRule: scheduleRule ?? old.scheduleRule,
        preferredTime: preferredTime ?? old.preferredTime,
        status: status ?? old.status,
        skipDates: old.skipDates,
      );
      return true;
    }
    return false;
  }

  @override
  Future<bool> skipRecurringBookingDate(String id, DateTime skipDate) async {
    final index = recurringBookings.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final old = recurringBookings[index];
      final newDates = List<String>.from(old.skipDates)..add(skipDate.toIso8601String().split('T').first);
      recurringBookings[index] = RecurringBooking(
        id: old.id,
        providerId: old.providerId,
        workerId: old.workerId,
        workerName: old.workerName,
        workerAvatar: old.workerAvatar,
        categoryId: old.categoryId,
        categoryName: old.categoryName,
        scheduleRule: old.scheduleRule,
        preferredTime: old.preferredTime,
        status: old.status,
        skipDates: newDates,
      );
      return true;
    }
    return false;
  }

  @override
  Future<WageBandInfo?> fetchWageBand({required String categoryId, String? area}) async {
    return const WageBandInfo(minPaise: 70000, maxPaise: 100000, unit: 'day');
  }
}

Widget createTestApp({required Widget child, required MockBookingRepository mockRepo}) {
  return ProviderScope(
    overrides: [
      bookingRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('BookingDraft and BookedSlot Domain Tests', () {
    test('Calculates totals, platform fee, and protection cover accurately', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final draftWithoutProtection = BookingDraft(
        workerId: 'w1',
        workerName: 'Suresh',
        categoryName: 'Electrician',
        dailyRatePaise: 80000,
        wagePaise: 80000,
        platformFeePaise: 4500,
        protectionCoverPaise: 4000,
        isProtectionSelected: false,
        selectedDate: tomorrow,
      );

      expect(draftWithoutProtection.totalPaise, 84500); // 800 + 45 = 845
      expect(draftWithoutProtection.formattedTotal, '₹845');

      final draftWithProtection = draftWithoutProtection.copyWith(isProtectionSelected: true);
      expect(draftWithProtection.totalPaise, 88500); // 800 + 45 + 40 = 885
      expect(draftWithProtection.formattedTotal, '₹885');
    });

    test('BookedSlot accurately detects schedule overlaps', () {
      final slotStart = DateTime(2026, 10, 10, 10, 0);
      final slotEnd = DateTime(2026, 10, 10, 14, 0);
      final slot = BookedSlot(
        assignmentId: 'asgn-1',
        jobId: 'job-1',
        startAt: slotStart,
        endAt: slotEnd,
        status: 'accepted',
      );

      // Candidate 1: Starts at 9:00 AM for 4 hours (ends at 1:00 PM) -> Overlaps
      expect(slot.overlapsWith(DateTime(2026, 10, 10, 9, 0), 240), isTrue);

      // Candidate 2: Starts at 2:00 PM for 4 hours (ends at 6:00 PM) -> No overlap
      expect(slot.overlapsWith(DateTime(2026, 10, 10, 14, 0), 240), isFalse);

      // Candidate 3: Starts at 6:00 AM for 3 hours (ends at 9:00 AM) -> No overlap
      expect(slot.overlapsWith(DateTime(2026, 10, 10, 6, 0), 180), isFalse);
    });
  });

  group('GuidedBookingScreen Widget Tests', () {
    testWidgets('Unverified worker shows dark-panel notice with ₹40 protection option', (tester) async {
      final mockRepo = MockBookingRepository();
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final unverifiedDraft = BookingDraft(
        workerId: 'w-unverified',
        workerName: 'Manju Nathan',
        categoryName: 'Painter',
        isWorkerVerified: false, // UNVERIFIED!
        dailyRatePaise: 75000,
        wagePaise: 75000,
        selectedDate: tomorrow,
        currentStep: 6, // Step 6 is Confirm / Notice
      );

      await tester.pumpWidget(createTestApp(
        child: GuidedBookingScreen(initialDraft: unverifiedDraft),
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Check dark panel screen header
      expect(find.text('Not UdyogaSethu Verified'), findsWidgets);
      expect(find.text('Add ₹40 Job Protection Cover'), findsOneWidget);
      expect(find.text('Demo mode'), findsOneWidget);
      expect(find.text('Book without protection'), findsOneWidget);
      expect(find.text('Confirm & Proceed to Booking Pass Ticket'), findsOneWidget);

      // Tap Confirm and proceed
      await tester.tap(find.text('Confirm & Proceed to Booking Pass Ticket'));
      await tester.pumpAndSettle();

      // Ticket screen appears with Booking Pass Ticket and Waiting for worker status
      expect(find.text('Booking Pass Ticket'), findsOneWidget);
      expect(find.text('Waiting for worker'), findsOneWidget);
      expect(find.textContaining('BOOK-TEST1'), findsOneWidget);
    });

    testWidgets('Verified worker skips unverified notice and proceeds directly', (tester) async {
      final mockRepo = MockBookingRepository();
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final verifiedDraft = BookingDraft(
        workerId: 'w-verified',
        workerName: 'Ramesh Kumar',
        categoryName: 'Electrician',
        isWorkerVerified: true, // VERIFIED!
        dailyRatePaise: 85000,
        wagePaise: 85000,
        selectedDate: tomorrow,
        currentStep: 6, // Step 6
      );

      await tester.pumpWidget(createTestApp(
        child: GuidedBookingScreen(initialDraft: verifiedDraft),
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Verified notice is skipped
      expect(find.text('Verified Worker — Notice Skipped'), findsOneWidget);
      expect(find.text('Not UdyogaSethu Verified'), findsNothing);
      expect(find.text('Confirm & Proceed to Booking Pass Ticket'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm & Proceed to Booking Pass Ticket'));
      await tester.pumpAndSettle();

      // Ticket screen appears directly
      expect(find.text('Booking Pass Ticket'), findsOneWidget);
      expect(find.text('Waiting for worker'), findsOneWidget);
    });
  });

  group('RecurringBookingsScreen Widget Tests', () {
    testWidgets('Renders active recurring booking rules with pause and skip actions', (tester) async {
      final mockRepo = MockBookingRepository();

      await tester.pumpWidget(createTestApp(
        child: const RecurringBookingsScreen(),
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Services'), findsOneWidget);
      expect(find.text('Chethan Kumar'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pause Schedule'), findsOneWidget);
      expect(find.text('Skip Next Date'), findsOneWidget);

      // Tap Pause Schedule
      await tester.tap(find.text('Pause Schedule'));
      await tester.pumpAndSettle();

      // It pauses and shows Resume Schedule
      expect(find.text('Resume Schedule'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
    });
  });
}
