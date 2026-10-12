import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/services/job_thumbnail_service.dart';
import 'package:udyogasethu/core/widgets/job_row.dart';
import 'package:udyogasethu/features/provider/domain/job_post_draft.dart';
import 'package:udyogasethu/features/provider/presentation/provider_jobs_controller.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part B - Job Post Draft & Students Welcome Logic Tests', () {
    test('JobPostDraft defaults suitableFor strictly to informal and studentsOk to false', () {
      final draft = JobPostDraft(startAt: DateTime.now());
      expect(draft.suitableFor, ['informal']);
      expect(draft.studentsOk, isFalse);
    });

    test('PostJobWizardNotifier setSuitableFor sets studentsOk based on student inclusion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postJobWizardProvider.notifier);

      // Initially false
      expect(container.read(postJobWizardProvider).studentsOk, isFalse);

      // Select student
      notifier.setSuitableFor(['informal', 'student']);
      expect(container.read(postJobWizardProvider).studentsOk, isTrue);
      expect(container.read(postJobWizardProvider).suitableFor, contains('student'));

      // Remove student
      notifier.setSuitableFor(['informal']);
      expect(container.read(postJobWizardProvider).studentsOk, isFalse);
      expect(container.read(postJobWizardProvider).suitableFor, isNot(contains('student')));
    });

    test('PostJobWizardNotifier setRequirements syncs suitableFor list properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postJobWizardProvider.notifier);

      // Turn on studentsOk
      notifier.setRequirements(studentsOk: true);
      expect(container.read(postJobWizardProvider).studentsOk, isTrue);
      expect(container.read(postJobWizardProvider).suitableFor, contains('student'));

      // Turn off studentsOk
      notifier.setRequirements(studentsOk: false);
      expect(container.read(postJobWizardProvider).studentsOk, isFalse);
      expect(container.read(postJobWizardProvider).suitableFor, isNot(contains('student')));
      expect(container.read(postJobWizardProvider).suitableFor, contains('informal'));
    });
  });

  group('Part B - Keyword-aware Thumbnail Selector Tests', () {
    final service = JobThumbnailService();

    test('Prioritizes provider site photo above all keyword and category defaults', () {
      final thumb = service.selectThumbnail(
        sitePhotoUrl: 'https://example.com/real_work_site.jpg',
        categorySlug: 'plumbing',
        jobId: 'job-123',
        title: 'Emergency pipe repair',
      );

      expect(thumb.isNetwork, isTrue);
      expect(thumb.sourceType, ThumbnailSourceType.network);
      expect(thumb.uri, 'https://example.com/real_work_site.jpg');
    });

    test('Selects keyword-matched category when title or description contains strong keywords', () {
      // 1. Electrician
      final elec = service.selectThumbnail(
        categorySlug: 'general',
        jobId: 'j-1',
        title: 'Complete house wiring and switchboard replacement',
      );
      expect(elec.isNetwork, isFalse);
      expect(elec.uri, 'assets/thumbnails/electrician.webp');

      // 2. Plumbing
      final plumb = service.selectThumbnail(
        categorySlug: 'general',
        jobId: 'j-2',
        title: 'Fix bathroom tap leak and water tank pipe',
      );
      expect(plumb.isNetwork, isFalse);
      expect(plumb.uri, 'assets/thumbnails/plumbing.webp');

      // 3. Carpenter
      final carp = service.selectThumbnail(
        categorySlug: 'general',
        jobId: 'j-3',
        title: 'Custom wooden dining table and furniture fixing',
      );
      expect(carp.isNetwork, isFalse);
      expect(carp.uri, 'assets/thumbnails/carpenter.webp');

      // 4. Cleaner
      final clean = service.selectThumbnail(
        categorySlug: 'general',
        jobId: 'j-4',
        title: 'Deep office cleaning and dusting',
      );
      expect(clean.isNetwork, isFalse);
      expect(clean.uri, 'assets/thumbnails/cleaner.webp');
    });

    test('Falls back to category slug and generic when no keywords match', () {
      final fallback = service.selectThumbnail(
        categorySlug: 'mason',
        jobId: 'j-5',
        title: 'Miscellaneous manual help',
      );
      expect(fallback.isNetwork, isFalse);
      expect(fallback.uri, 'assets/thumbnails/mason.webp');

      final unknown = service.selectThumbnail(
        categorySlug: 'unknown_trade',
        jobId: 'j-6',
        title: 'Some unspecified task',
      );
      expect(unknown.isNetwork, isFalse);
      expect(unknown.uri, 'assets/thumbnails/fallback_generic.webp');
    });

    test('Wall paint keyword gives painting library thumbnail', () {
      final interior = service.selectThumbnail(
        categorySlug: 'painting',
        jobId: 'j-7',
        title: 'Need 2BHK wall paint and plaster touchup',
      );
      expect(interior.isNetwork, isFalse);
      expect(interior.uri, 'assets/thumbnails/painting.webp');
    });

    test('Priority sequence: provider site photo > library illustration > fallback', () {
      // 1. Site photo takes priority even if title has "wall paint"
      final siteThumb = service.selectThumbnail(
        sitePhotoUrl: 'https://example.com/actual_room.jpg',
        categorySlug: 'painting',
        jobId: 'j-8',
        title: 'Urgent wall paint job',
      );
      expect(siteThumb.isNetwork, isTrue);
      expect(siteThumb.uri, 'https://example.com/actual_room.jpg');

      // 2. Without site photo, library illustration is resolved
      final libThumb = service.selectThumbnail(
        categorySlug: 'painting',
        jobId: 'j-8',
        title: 'Urgent wall paint job',
      );
      expect(libThumb.isNetwork, isFalse);
      expect(libThumb.uri, 'assets/thumbnails/painting.webp');
    });
  });

  group('Part B - JobRow Students Welcome Widget Tests', () {
    testWidgets('JobRow renders Students Welcome badge only when studentsOk is true', (tester) async {
      const jobWithStudents = JobRecommendation(
        id: 'job-s1',
        providerId: 'p1',
        title: 'Food Delivery Evening Shift',
        wageType: 'daily',
        wagePaise: 80000,
        employerName: 'Quick Commerce',
        categorySlug: 'delivery-gig-work',
        studentsOk: true,
      );

      const jobWithoutStudents = JobRecommendation(
        id: 'job-s2',
        providerId: 'p2',
        title: 'Masonry Wall Building',
        wageType: 'daily',
        wagePaise: 90000,
        employerName: 'City Builders',
        categorySlug: 'mason',
        studentsOk: false,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    JobRow(job: jobWithStudents),
                    JobRow(job: jobWithoutStudents),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Exactly ONE Students Welcome badge should exist (for jobWithStudents only!)
      expect(find.text('Students Welcome'), findsOneWidget);
    });
  });
}
