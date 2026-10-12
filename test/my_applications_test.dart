import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:udyogasethu/core/router/app_session.dart';
import 'package:udyogasethu/core/widgets/job_action_button.dart';
import 'package:udyogasethu/core/widgets/job_row.dart';
import 'package:udyogasethu/features/seeker/data/my_applications_repository.dart';
import 'package:udyogasethu/features/seeker/domain/job_application_status.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';
import 'package:udyogasethu/features/seeker/presentation/my_applications_controller.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockMyApplicationsRepository implements MyApplicationsRepository {
  final Map<String, WorkerJobStatus> initialStatuses;
  bool shouldFailApply = false;
  String failApplyMessage = 'Simulated network failure';
  bool shouldFailWithdraw = false;
  void Function(Map<String, dynamic> record, String table, String eventType)? onRealtimeEvent;

  MockMyApplicationsRepository({this.initialStatuses = const {}});

  @override
  Future<Map<String, WorkerJobStatus>> fetchMyApplicationStatuses() async {
    return initialStatuses;
  }

  @override
  RealtimeChannel? subscribeToUserChanges({
    required void Function(Map<String, dynamic> record, String table, String eventType) onRecordChanged,
  }) {
    onRealtimeEvent = onRecordChanged;
    return null;
  }

  @override
  Future<String> applyToJob({required String jobId, String? message}) async {
    if (shouldFailApply) {
      throw Exception(failApplyMessage);
    }
    return 'app-$jobId-1234';
  }

  @override
  Future<bool> withdrawApplication(String jobId) async {
    if (shouldFailWithdraw) {
      throw Exception('Simulated withdrawal failure');
    }
    return true;
  }
}

void main() {
  group('MyApplicationsProvider Unit Tests', () {
    test('Initializes and seeds remote applications', () async {
      final mockRepo = MockMyApplicationsRepository(
        initialStatuses: {
          'job-1': const WorkerJobStatus(
            jobId: 'job-1',
            applicationStatus: JobAppStatus.applied,
            applicationId: 'app-1',
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myApplicationsProvider.notifier).loadAll();
      final state = container.read(myApplicationsProvider);

      expect(state.containsKey('job-1'), isTrue);
      expect(state['job-1']!.isApplied, isTrue);
      expect(state['job-1']!.applicationId, equals('app-1'));
    });

    test('Optimistic apply updates state immediately and succeeds', () async {
      final mockRepo = MockMyApplicationsRepository();
      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(myApplicationsProvider.notifier);
      final applyFuture = notifier.applyToJob(jobId: 'job-2');

      // Check immediate optimistic state
      expect(container.read(myApplicationsProvider)['job-2']?.isApplied, isTrue);

      final result = await applyFuture;
      expect(result.success, isTrue);
      expect(result.applicationId, equals('app-job-2-1234'));
      expect(container.read(myApplicationsProvider)['job-2']?.applicationId, equals('app-job-2-1234'));
    });

    test('Optimistic apply rolls back upon server failure with clear error', () async {
      final mockRepo = MockMyApplicationsRepository()
        ..shouldFailApply = true
        ..failApplyMessage = 'Ineligible to apply: ["Driving licence is required."]';

      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(myApplicationsProvider.notifier);
      final result = await notifier.applyToJob(jobId: 'job-3');

      expect(result.success, isFalse);
      expect(result.error, contains('Driving licence is required.'));

      // Rolled back - job-3 should no longer be marked applied
      expect(container.read(myApplicationsProvider)['job-3'], isNull);
    });

    test('Optimistic withdraw transitions to withdrawn and rolls back on failure', () async {
      final mockRepo = MockMyApplicationsRepository(
        initialStatuses: {
          'job-4': const WorkerJobStatus(
            jobId: 'job-4',
            applicationStatus: JobAppStatus.applied,
            applicationId: 'app-4',
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myApplicationsProvider.notifier).loadAll();
      final notifier = container.read(myApplicationsProvider.notifier);

      // Successful withdrawal
      final successResult = await notifier.withdrawApplication('job-4');
      expect(successResult.success, isTrue);
      expect(container.read(myApplicationsProvider)['job-4']?.isWithdrawn, isTrue);

      // Reset to applied and simulate failure
      notifier.seedStatuses([
        const WorkerJobStatus(jobId: 'job-5', applicationStatus: JobAppStatus.applied),
      ]);
      mockRepo.shouldFailWithdraw = true;

      final failResult = await notifier.withdrawApplication('job-5');
      expect(failResult.success, isFalse);
      // Reverted to applied
      expect(container.read(myApplicationsProvider)['job-5']?.isApplied, isTrue);
    });

    test('Supabase Realtime updates modify state in place', () async {
      final mockRepo = MockMyApplicationsRepository();
      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myApplicationsProvider.notifier).loadAll();
      expect(mockRepo.onRealtimeEvent, isNotNull);

      // Simulate Realtime event for job_applications transition to shortlisted
      mockRepo.onRealtimeEvent!(
        {
          'id': 'app-99',
          'job_id': 'job-99',
          'status': 'shortlisted',
          'created_at': DateTime.now().toIso8601String(),
        },
        'job_applications',
        'UPDATE',
      );

      final state = container.read(myApplicationsProvider);
      expect(state['job-99']?.isShortlisted, isTrue);

      // Simulate Realtime event for job_assignments hired/accepted
      mockRepo.onRealtimeEvent!(
        {
          'id': 'asg-99',
          'job_id': 'job-99',
          'status': 'ticket_issued',
        },
        'job_assignments',
        'INSERT',
      );

      final updatedState = container.read(myApplicationsProvider);
      expect(updatedState['job-99']?.isHired, isTrue);
      expect(updatedState['job-99']?.assignmentId, equals('asg-99'));
    });

    test('Sign out clears application statuses completely', () async {
      final mockRepo = MockMyApplicationsRepository(
        initialStatuses: {
          'job-x': const WorkerJobStatus(
            jobId: 'job-x',
            applicationStatus: JobAppStatus.applied,
          ),
        },
      );

      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(myApplicationsProvider.notifier).loadAll();
      expect(container.read(myApplicationsProvider).isNotEmpty, isTrue);

      // Trigger sign out on session notifier
      container.read(appSessionProvider.notifier).setSessionStatus(AuthSessionStatus.signedOut);

      expect(container.read(myApplicationsProvider).isEmpty, isTrue);
    });
  });

  group('JobActionButton Widget Tests', () {
    testWidgets('Same job shows Applied across Home JobRow and JobDetail after applying', (tester) async {
      final mockRepo = MockMyApplicationsRepository();
      final container = ProviderContainer(
        overrides: [
          myApplicationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      const testJob = JobRecommendation(
        id: 'job-shared-1',
        providerId: 'prov-1',
        title: 'Carpentry Shift',
        wageType: 'daily',
        wagePaise: 85000,
        employerName: 'Sharma Contractors',
      );

      Widget buildTestApp(Widget child) {
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          ),
        );
      }

      // 1. Initial State: JobRow shows "Apply Now"
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              // Home Screen Card representation
              JobRow(job: testJob),
              // Job Detail Screen Bottom Bar representation
              JobActionButton(
                jobId: 'job-shared-1',
                jobTitle: 'Carpentry Shift',
                isCompact: false,
                showWithdrawOption: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply Now'), findsOneWidget);
      expect(find.text('Apply Now (Quick & Easy ✨)'), findsOneWidget);
      expect(find.text('Applied ✓'), findsNothing);

      // 2. Tap Apply on the Home JobRow button
      await tester.tap(find.text('Apply Now'));
      await tester.pump(); // Start async optimistic update

      // 3. Both Home JobRow and JobDetail button must now show Applied ✓
      expect(find.text('Applied ✓'), findsNWidgets(2));
      expect(find.text('Withdraw'), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
