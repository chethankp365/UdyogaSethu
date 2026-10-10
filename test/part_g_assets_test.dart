import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/services/job_thumbnail_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part G: Job Assets and Manifest Invariants', () {
    test('Job manifest contains 20 categories and all 40 WebP files exist', () {
      final manifestFile = File('assets/images/jobs/manifest.json');
      expect(manifestFile.existsSync(), isTrue, reason: 'jobs manifest.json must exist');

      final data = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final categories = data['categories'] as List<dynamic>;

      expect(categories.length, greaterThanOrEqualTo(20));

      int totalVariants = 0;
      for (final cat in categories) {
        final map = cat as Map<String, dynamic>;
        final slug = map['slug'] as String;
        expect(slug.isNotEmpty, isTrue);
        final variants = map['variants'] as List<dynamic>;

        expect(variants.length, equals(2), reason: 'Every job category must have 2 variants');
        totalVariants += variants.length;

        for (final v in variants) {
          final file = File(v.toString());
          expect(file.existsSync(), isTrue, reason: 'Variant file $v must exist on disk');
        }
      }

      expect(totalVariants, greaterThanOrEqualTo(40), reason: 'Must have at least 40 job variant images');
    });

    test('JobThumbnailService keyword resolver handles gardener and core slugs', () {
      final service = JobThumbnailService()..init();

      // Test gardener keyword resolution
      final thumbGardener = service.selectThumbnail(
        categorySlug: 'general',
        jobId: 'job-101',
        title: 'Need expert gardener for lawn mowing and plant care',
      );
      expect(thumbGardener.categorySlug, equals('gardener'));
      expect(thumbGardener.uri, contains('assets/images/jobs/gardener-'));

      // Test site photo priority
      final thumbSite = service.selectThumbnail(
        sitePhotoUrl: 'https://example.com/site.jpg',
        categorySlug: 'electrician',
        jobId: 'job-102',
      );
      expect(thumbSite.isNetwork, isTrue);
      expect(thumbSite.uri, equals('https://example.com/site.jpg'));
    });
  });

  group('Part G: Commodity Assets and Manifest Invariants', () {
    test('Commodity manifest contains 40 commodities and all 40 WebP files exist', () {
      final manifestFile = File('assets/images/commodities/manifest.json');
      expect(manifestFile.existsSync(), isTrue, reason: 'commodities manifest.json must exist');

      final data = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final commodities = data['commodities'] as List<dynamic>;

      expect(commodities.length, equals(40), reason: 'Must contain exactly 40 agricultural commodities');

      for (final item in commodities) {
        final map = item as Map<String, dynamic>;
        final slug = map['slug'] as String;
        final path = map['assetPath'] as String;

        expect(slug.isNotEmpty, isTrue);
        expect(map['name'], isNotNull);
        expect(map['category'], isNotNull);
        expect(map['emoji'], isNotNull);

        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Commodity asset $path must exist on disk');
      }
    });
  });

  group('Part G: Fallback Loaders Widget Test', () {
    testWidgets('JobThumbnailWidget renders without crash and handles fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: JobThumbnailWidget(
                categorySlug: 'gardener',
                jobId: 'test-123',
                width: 80,
                height: 80,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(JobThumbnailWidget), findsOneWidget);
    });
  });
}
