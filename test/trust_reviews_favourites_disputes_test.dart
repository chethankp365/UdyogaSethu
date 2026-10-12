import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udyogasethu/features/trust/data/trust_repository.dart';
import 'package:udyogasethu/features/trust/domain/dispute.dart';
import 'package:udyogasethu/features/trust/domain/favourite_item.dart';
import 'package:udyogasethu/features/trust/domain/job_history_item.dart';
import 'package:udyogasethu/features/trust/domain/job_review.dart';
import 'package:udyogasethu/features/trust/domain/repeat_client.dart';
import 'package:udyogasethu/features/trust/presentation/favourites_screen.dart';
import 'package:udyogasethu/features/trust/presentation/job_history_screen.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/raise_dispute_dialog.dart';
import 'package:udyogasethu/features/trust/presentation/widgets/rate_job_dialog.dart';
import 'package:udyogasethu/l10n/app_localizations.dart';

class MockTrustRepository implements TrustRepository {
  bool submitReviewCalled = false;
  int? submittedStars;
  List<String>? submittedTags;
  String? submittedComment;

  bool createDisputeCalled = false;
  DisputeIssueType? submittedIssueType;
  String? submittedDetails;

  bool toggleFavouriteCalled = false;
  String? toggledTargetId;

  bool shouldThrowDuplicateReview = false;

  final List<JobHistoryItem> historyItems;
  final List<FavouriteItem> favouriteItems;
  final List<RepeatClientItem> repeatClientItems;

  MockTrustRepository({
    this.historyItems = const [],
    this.favouriteItems = const [],
    this.repeatClientItems = const [],
  });

  @override
  Future<String> submitJobReview({
    required String assignmentId,
    required int stars,
    List<String> tags = const [],
    String? comment,
  }) async {
    if (shouldThrowDuplicateReview) {
      throw Exception('You have already submitted a review for this job. Duplicate reviews are not permitted.');
    }
    submitReviewCalled = true;
    submittedStars = stars;
    submittedTags = tags;
    submittedComment = comment;
    return 'rev-test-123';
  }

  @override
  Future<String> createAssignmentDispute({
    required String assignmentId,
    required DisputeIssueType issueType,
    required String details,
    List<String> evidencePaths = const [],
  }) async {
    createDisputeCalled = true;
    submittedIssueType = issueType;
    submittedDetails = details;
    return 'disp-test-123';
  }

  @override
  Future<List<JobHistoryItem>> fetchJobHistory({String? status, int limit = 50, int offset = 0}) async {
    if (status == null || status == 'all') return historyItems;
    return historyItems.where((i) => i.status == status).toList();
  }

  @override
  Future<bool> toggleFavourite(String targetId) async {
    toggleFavouriteCalled = true;
    toggledTargetId = targetId;
    return true;
  }

  @override
  Future<List<FavouriteItem>> fetchFavourites({int limit = 50, int offset = 0}) async {
    return favouriteItems;
  }

  @override
  Future<List<RepeatClientItem>> fetchRepeatClients([String? workerId]) async {
    return repeatClientItems;
  }

  @override
  Future<List<JobReview>> fetchUserReviews(String userId, {int limit = 20, int offset = 0}) async {
    return [];
  }

  @override
  Future<String> uploadDisputeEvidence({
    required String assignmentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return 'evidence/$assignmentId/$fileName';
  }
}

void main() {
  group('P4.11 Domain Serialization Tests', () {
    test('JobReview serialization and deserialization', () {
      final json = {
        'id': 'rev-1',
        'ref_type': 'job_assignment',
        'ref_id': 'assign-1',
        'rater_id': 'user-1',
        'target_id': 'user-2',
        'stars': 5,
        'tags': ['On Time', 'Professional'],
        'comment': 'Exceptional service and timely arrival.',
        'created_at': '2026-10-09T10:00:00.000Z',
      };

      final review = JobReview.fromJson(json);
      expect(review.id, 'rev-1');
      expect(review.stars, 5);
      expect(review.tags, contains('On Time'));
      expect(review.comment, 'Exceptional service and timely arrival.');

      final output = review.toJson();
      expect(output['stars'], 5);
      expect(output['ref_type'], 'job_assignment');
    });

    test('DisputeRecord serialization and deserialization', () {
      final json = {
        'id': 'disp-1',
        'ref_type': 'job_assignment',
        'ref_id': 'assign-1',
        'raised_by': 'user-1',
        'against': 'user-2',
        'issue_type': 'incomplete_work',
        'details': 'Worker left before finishing all tasks.',
        'status': 'open',
        'created_at': '2026-10-09T10:30:00.000Z',
        'evidence': ['evidence/1.jpg'],
      };

      final dispute = DisputeRecord.fromJson(json);
      expect(dispute.id, 'disp-1');
      expect(dispute.issueType, DisputeIssueType.incompleteWork);
      expect(dispute.status, DisputeStatus.open);
      expect(dispute.details, 'Worker left before finishing all tasks.');
      expect(dispute.evidencePaths, contains('evidence/1.jpg'));
    });

    test('FavouriteItem parses and calculates dailyRateRupees', () {
      final json = {
        'target_id': 'worker-1',
        'full_name': 'Ramesh Electrician',
        'role': 'seeker',
        'headline': 'Experienced Electrician',
        'rating_avg': 4.9,
        'rating_count': 18,
        'jobs_completed': 25,
        'is_verified': true,
        'daily_rate_paise': 80000,
        'skills': [
          {'name': 'Wiring'},
          {'name': 'Appliance Repair'}
        ],
        'favourited_at': '2026-10-09T08:00:00.000Z',
      };

      final fav = FavouriteItem.fromJson(json);
      expect(fav.targetId, 'worker-1');
      expect(fav.fullName, 'Ramesh Electrician');
      expect(fav.dailyRateRupees, 800);
      expect(fav.skills, contains('Wiring'));
    });

    test('JobHistoryItem formats timeAgo and detects disputed state', () {
      final now = DateTime.now();
      final item = JobHistoryItem(
        assignmentId: 'assign-1',
        jobId: 'job-1',
        title: 'Construction Helper',
        wagePaise: 60000,
        agreedWagePaise: 60000,
        status: 'disputed',
        completedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        categorySlug: 'construction',
        categoryName: 'Construction',
        area: 'JP Nagar, Bengaluru',
        counterpartyId: 'cp-1',
        counterpartyName: 'Sharma Builders',
        counterpartyRole: 'employer',
        counterpartyVerified: true,
        isFavourite: false,
        canReview: false,
        canDispute: false,
        canRebook: true,
      );

      expect(item.amountRupees, 600);
      expect(item.timeAgo, '3d ago');
      expect(item.isDisputed, isTrue);
    });
  });

  group('P4.11 Widget & Interaction Tests', () {
    testWidgets('RateJobDialog renders, selects tags, and submits review', (tester) async {
      final mockRepo = MockTrustRepository();
      bool reviewCallbackTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trustRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RateJobDialog(
                assignmentId: 'assign-test',
                jobTitle: 'Commercial Electrical Repair',
                counterpartyName: 'Chethan Kumar',
                onReviewSubmitted: () => reviewCallbackTriggered = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and star ratings
      expect(find.text('Rate & Review Job'), findsOneWidget);
      expect(find.text('Commercial Electrical Repair • Chethan Kumar'), findsOneWidget);

      // Select a tag: "On Time"
      final onTimeChip = find.text('⏱️ On Time');
      expect(onTimeChip, findsOneWidget);
      await tester.tap(onTimeChip);
      await tester.pumpAndSettle();

      // Enter review comment
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Excellent and punctual electrician.');
      await tester.pumpAndSettle();

      // Tap submit button
      final submitBtn = find.text('Submit Verified Review');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.submitReviewCalled, isTrue);
      expect(mockRepo.submittedStars, 5);
      expect(mockRepo.submittedTags, contains('On Time'));
      expect(mockRepo.submittedComment, 'Excellent and punctual electrician.');
      expect(reviewCallbackTriggered, isTrue);
    });

    testWidgets('Duplicate review attempt is caught and refused with error message', (tester) async {
      final mockRepo = MockTrustRepository()..shouldThrowDuplicateReview = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trustRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RateJobDialog(
                assignmentId: 'assign-test',
                jobTitle: 'Commercial Electrical Repair',
                counterpartyName: 'Chethan Kumar',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final submitBtn = find.text('Submit Verified Review');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify that duplicate error is displayed
      expect(
        find.text('You have already submitted a review for this job. Duplicate reviews are not permitted.'),
        findsOneWidget,
      );
    });

    testWidgets('RaiseDisputeDialog renders issue types, details and submits dispute', (tester) async {
      final mockRepo = MockTrustRepository();
      bool disputeCallbackTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trustRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RaiseDisputeDialog(
                assignmentId: 'assign-test',
                jobTitle: 'Commercial Electrical Repair',
                counterpartyName: 'Sharma Builders',
                onDisputeRaised: () => disputeCallbackTriggered = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Report Job Dispute'), findsOneWidget);
      expect(
        find.text(
          'Filing a dispute pauses automatic escrow release and assigns the case to UdyogaSethu Trust & Safety for review.',
        ),
        findsOneWidget,
      );

      // Select issue type: "Incomplete Work"
      final incompleteWorkChip = find.text('Incomplete Work / Left Early');
      expect(incompleteWorkChip, findsOneWidget);
      await tester.tap(incompleteWorkChip);
      await tester.pumpAndSettle();

      // Enter details
      final detailsField = find.byType(TextField);
      expect(detailsField, findsOneWidget);
      await tester.enterText(detailsField, 'Worker left at 2 PM without completing the electrical wiring.');
      await tester.pumpAndSettle();

      // Tap submit
      final submitBtn = find.text('Raise Formal Dispute');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.createDisputeCalled, isTrue);
      expect(mockRepo.submittedIssueType, DisputeIssueType.incompleteWork);
      expect(mockRepo.submittedDetails, 'Worker left at 2 PM without completing the electrical wiring.');
      expect(disputeCallbackTriggered, isTrue);
    });

    testWidgets('JobHistoryScreen renders history items and supports filters', (tester) async {
      final now = DateTime.now();
      final mockItems = [
        JobHistoryItem(
          assignmentId: 'assign-1',
          jobId: 'job-1',
          title: 'Construction Helper',
          wagePaise: 60000,
          agreedWagePaise: 60000,
          status: 'completed',
          completedAt: now.subtract(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(days: 2)),
          categorySlug: 'construction',
          categoryName: 'Construction Helper',
          area: 'JP Nagar, Bengaluru',
          counterpartyId: 'cp-1',
          counterpartyName: 'Sharma Builders',
          counterpartyRole: 'employer',
          counterpartyVerified: true,
          isFavourite: true,
          userReview: JobReview(
            id: 'rev-1',
            stars: 5,
            tags: ['On Time'],
            comment: 'Great work',
            createdAt: now,
          ),
          canReview: false,
          canDispute: true,
          canRebook: true,
        ),
      ];

      final mockRepo = MockTrustRepository(historyItems: mockItems);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trustRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: JobHistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen 37 elements
      expect(find.text('Job History & Ratings'), findsOneWidget);
      expect(find.text('Construction Helper'), findsOneWidget);
      expect(find.text('₹600'), findsOneWidget);
      expect(find.text('Reviewed (5★)'), findsOneWidget);
      expect(find.text('Rebook'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('FavouritesScreen renders saved partners and allows booking', (tester) async {
      final mockFavourites = [
        FavouriteItem(
          targetId: 'w-1',
          fullName: 'Anand Kumar',
          role: 'seeker',
          headline: 'Expert Plumber',
          ratingAvg: 4.9,
          ratingCount: 30,
          jobsCompleted: 45,
          isVerified: true,
          dailyRatePaise: 75000,
          skills: ['Plumbing', 'Pipe Repair'],
          favouritedAt: DateTime.now(),
        ),
      ];

      final mockRepo = MockTrustRepository(favouriteItems: mockFavourites);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trustRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FavouritesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Favourites & Trust Circles'), findsOneWidget);
      expect(find.text('Anand Kumar'), findsOneWidget);
      expect(find.text('Expert Plumber'), findsOneWidget);
      expect(find.text('₹750/day'), findsOneWidget);
      expect(find.text('Book Again'), findsOneWidget);
    });
  });
}
