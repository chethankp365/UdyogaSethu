import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';
import '../domain/booked_slot.dart';
import '../domain/booking_draft.dart';
import '../domain/booking_result.dart';
import '../domain/recurring_booking.dart';
import '../domain/user_address.dart';

final savedAddressesProvider = FutureProvider<List<UserAddress>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.fetchSavedAddresses();
});

final workerBookedSlotsProvider = FutureProvider.family<List<BookedSlot>, String>((ref, workerId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final now = DateTime.now();
  final end = now.add(const Duration(days: 30));
  return repo.fetchWorkerBookedSlots(workerId, now, end);
});

final wageBandProvider = FutureProvider.family<WageBandInfo?, String>((ref, categoryId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.fetchWageBand(categoryId: categoryId);
});

class BookingWizardNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() {
    return BookingDraft(
      workerId: 'worker-sample',
      workerName: 'Sample Worker',
      categoryName: 'Electrician',
      selectedDate: DateTime.now().add(const Duration(days: 1)),
    );
  }

  void initialize(BookingDraft draft) {
    state = draft;
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 6) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < 6) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateServiceDetails({String? title, String? notes, int? durationMinutes}) {
    state = state.copyWith(
      title: title,
      notes: notes,
      durationMinutes: durationMinutes,
    );
  }

  void updateDateTime({required DateTime date, required int hour, required int minute}) {
    state = state.copyWith(
      selectedDate: date,
      selectedTimeHour: hour,
      selectedTimeMinute: minute,
    );
  }

  void selectSavedAddress(UserAddress address) {
    state = state.copyWith(
      selectedAddress: address,
      manualAddressText: address.formattedAddress,
      lat: address.lat,
      lng: address.lng,
    );
  }

  void setManualAddress({required String text, double? lat, double? lng}) {
    state = state.copyWith(
      clearSelectedAddress: true,
      manualAddressText: text,
      lat: lat,
      lng: lng,
    );
  }

  void updateWage(int wagePaise) {
    state = state.copyWith(wagePaise: wagePaise);
  }

  void setProtectionCover(bool selected) {
    state = state.copyWith(isProtectionSelected: selected);
  }

  void setPaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void updateRecurring({required bool isRecurring, String? rule, String? preferredTime}) {
    state = state.copyWith(
      isRecurring: isRecurring,
      recurringRule: rule ?? state.recurringRule,
      recurringTime: preferredTime ?? state.recurringTime,
    );
  }
}

final bookingWizardProvider = NotifierProvider<BookingWizardNotifier, BookingDraft>(BookingWizardNotifier.new);

class BookingSubmissionNotifier extends AsyncNotifier<BookingResult?> {
  @override
  Future<BookingResult?> build() async {
    return null;
  }

  Future<BookingResult?> submit(BookingDraft draft) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final result = await repo.submitDirectBooking(draft);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final bookingSubmissionProvider = AsyncNotifierProvider<BookingSubmissionNotifier, BookingResult?>(BookingSubmissionNotifier.new);

class RecurringBookingsNotifier extends AsyncNotifier<List<RecurringBooking>> {
  @override
  Future<List<RecurringBooking>> build() async {
    final repo = ref.read(bookingRepositoryProvider);
    return repo.fetchRecurringBookings();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(bookingRepositoryProvider);
      return repo.fetchRecurringBookings();
    });
  }

  Future<bool> pauseBooking(String id) async {
    final repo = ref.read(bookingRepositoryProvider);
    final success = await repo.updateRecurringBooking(id, status: 'paused');
    if (success) await load();
    return success;
  }

  Future<bool> resumeBooking(String id) async {
    final repo = ref.read(bookingRepositoryProvider);
    final success = await repo.updateRecurringBooking(id, status: 'active');
    if (success) await load();
    return success;
  }

  Future<bool> cancelBooking(String id) async {
    final repo = ref.read(bookingRepositoryProvider);
    final success = await repo.updateRecurringBooking(id, status: 'cancelled');
    if (success) await load();
    return success;
  }

  Future<bool> skipDate(String id, DateTime date) async {
    final repo = ref.read(bookingRepositoryProvider);
    final success = await repo.skipRecurringBookingDate(id, date);
    if (success) await load();
    return success;
  }
}

final recurringBookingsProvider = AsyncNotifierProvider<RecurringBookingsNotifier, List<RecurringBooking>>(RecurringBookingsNotifier.new);
