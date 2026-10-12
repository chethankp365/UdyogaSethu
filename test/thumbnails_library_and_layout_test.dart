import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/services/thumbnail_library.dart';
import 'package:udyogasethu/core/widgets/app_thumbnail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Thumbnail Library Architecture & Resolution Tests', () {
    test('Library defines exactly 41 thumbnails spanning services, gigs, produce, equipment & fallback', () {
      expect(ThumbnailLibrary.items.length, 41);

      final keys = ThumbnailLibrary.items.map((i) => i.key).toSet();
      // Service categories (12)
      expect(keys, containsAll([
        'construction', 'plumbing', 'painting', 'delivery', 'electrician',
        'carpenter', 'mason', 'cleaner', 'driver', 'domestic_help', 'agri_labour', 'loader'
      ]));

      // Student and flexible gigs (8)
      expect(keys, containsAll([
        'campus_ambassador', 'online_tutor', 'tutoring', 'research_assistant',
        'data_entry', 'event_helper', 'content_creation', 'social_media'
      ]));

      // Farm produce & crops (14)
      expect(keys, containsAll([
        'produce_vegetables', 'produce_fruits', 'produce_grains', 'produce_dairy',
        'produce_flowers', 'produce_local', 'crop_tomato', 'crop_onion',
        'crop_mango', 'crop_coconut', 'crop_paddy', 'crop_sugarcane', 'crop_banana', 'crop_cardamom'
      ]));

      // Equipment and resources (6)
      expect(keys, containsAll([
        'equipment_tractor', 'equipment_harvester', 'equipment_drone',
        'resource_seeds', 'resource_fertilizer', 'resource_cold_storage'
      ]));

      // Fallback
      expect(keys, contains('fallback_generic'));
    });

    test('Campus Ambassador uses user reference image and has baked-in title', () {
      final campusItem = ThumbnailLibrary.findByKey('campus_ambassador');
      expect(campusItem, isNotNull);
      expect(campusItem!.assetPath, 'assets/thumbnails/campus_ambassador.webp');
      expect(campusItem.hasBakedInTitle, isTrue);

      final res = ThumbnailLibrary.resolveJob(
        title: 'College Campus Ambassador Program 2026',
        categorySlug: 'campus-brand-promotion',
      );
      expect(res.assetPath, 'assets/thumbnails/campus_ambassador.webp');
      expect(res.hasBakedInTitle, isTrue);
    });

    test('Source priority: uploaded photo > dedicated title illustration > category > generic', () {
      // 1. Uploaded network photo wins over title
      final userPhoto = ThumbnailLibrary.resolveJob(
        thumbnailPath: 'https://storage.example.com/site.jpg',
        title: 'Campus Ambassador',
        categorySlug: 'marketing',
      );
      expect(userPhoto.isNetwork, isTrue);
      expect(userPhoto.networkUrl, 'https://storage.example.com/site.jpg');

      // 2. Dedicated title illustration wins over category
      final dedicated = ThumbnailLibrary.resolveJob(
        title: 'Online Tutor for High School Physics',
        categorySlug: 'cleaning', // mismatched category, title wins!
      );
      expect(dedicated.assetPath, 'assets/thumbnails/online_tutor.webp');

      // 3. Category illustration wins when title has no dedicated illustration
      final cat = ThumbnailLibrary.resolveJob(
        title: 'Work Shift on 12th Oct',
        categorySlug: 'electrician',
      );
      expect(cat.assetPath, 'assets/thumbnails/electrician.webp');

      // 4. Generic fallback when nothing matches
      final fallback = ThumbnailLibrary.resolveJob(
        title: 'Miscellaneous unknown gig',
        categorySlug: 'nonexistent',
      );
      expect(fallback.assetPath, 'assets/thumbnails/fallback_generic.webp');
    });

    test('Produce resolution: photo > individual crop > category > fallback', () {
      // 1. Specific crop
      final tomato = ThumbnailLibrary.resolveProduce(
        name: 'Fresh Red Tomatoes',
        category: 'Vegetables',
      );
      expect(tomato.assetPath, 'assets/thumbnails/crop_tomato.webp');

      // 2. Produce category
      final exoticVeg = ThumbnailLibrary.resolveProduce(
        name: 'Broccoli and Lettuce Box',
        category: 'Vegetables',
      );
      expect(exoticVeg.assetPath, 'assets/thumbnails/produce_vegetables.webp');

      // 3. Dairy produce
      final milk = ThumbnailLibrary.resolveProduce(
        name: 'Pure Desi Cow Milk 1L',
        category: 'Dairy',
      );
      expect(milk.assetPath, 'assets/thumbnails/produce_dairy.webp');
    });

    test('Resource resolution: photo > equipment type > fallback', () {
      final drone = ThumbnailLibrary.resolveResource(
        title: 'Agricultural Spraying Drone',
        resourceType: 'drone',
      );
      expect(drone.assetPath, 'assets/thumbnails/equipment_drone.webp');

      final tractor = ThumbnailLibrary.resolveResource(
        title: 'Mahindra 575 DI Tractor with Rotavator',
        resourceType: 'tractor',
      );
      expect(tractor.assetPath, 'assets/thumbnails/equipment_tractor.webp');
    });
  });

  group('Layout & Accessibility Tests (360dp, 412dp, textScale 1.6)', () {
    testWidgets('JobThumbnail renders without overflow at 360dp width and textScale 1.6 in Kannada', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: ListView(
                children: const [
                  JobThumbnail(
                    title: 'ಕಟ್ಟಡ ನಿರ್ಮಾಣ ಕಾರ್ಮಿಕ ಮತ್ತು ಗಾರೆ ಕೆಲಸ',
                    categorySlug: 'construction',
                    size: ThumbnailSize.card,
                    width: 340,
                    height: 191,
                  ),
                  SizedBox(height: 16),
                  JobThumbnail(
                    title: 'ತುರ್ತು ಪ್ಲಂಬಿಂಗ್ ದುರಸ್ತಿ',
                    categorySlug: 'plumbing',
                    size: ThumbnailSize.small,
                    width: 56,
                    height: 56,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(JobThumbnail), findsNWidgets(2));
    });

    testWidgets('JobThumbnail renders without overflow at 412dp width and textScale 1.6 in Hindi and Telugu', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.5, 900 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 900),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: ListView(
                children: const [
                  // Hindi
                  JobThumbnail(
                    title: 'भवन निर्माण श्रमिक एवं चिनाई कार्य',
                    categorySlug: 'construction',
                    size: ThumbnailSize.card,
                    width: 380,
                    height: 213,
                  ),
                  SizedBox(height: 16),
                  // Telugu
                  JobThumbnail(
                    title: 'ఎమర్జెన్సీ పైప్‌లైన్ మరియు ప్లంబింగ్ పని',
                    categorySlug: 'plumbing',
                    size: ThumbnailSize.header,
                    width: 412,
                    height: 220,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(JobThumbnail), findsNWidgets(2));
    });

    testWidgets('ProduceThumbnail and ResourceThumbnail render cleanly at 360dp with textScale 1.6 in Tamil', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: ListView(
                children: const [
                  ProduceThumbnail(
                    name: 'முதல் தர புதிய நாட்டு தக்காளி',
                    category: 'Vegetables',
                    size: ThumbnailSize.card,
                    width: 340,
                    height: 191,
                  ),
                  SizedBox(height: 16),
                  ResourceThumbnail(
                    title: 'ரோட்டாவேட்டருடன் டிராக்டர் வாடகைக்கு',
                    resourceType: 'tractor',
                    size: ThumbnailSize.card,
                    width: 340,
                    height: 191,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ProduceThumbnail), findsOneWidget);
      expect(find.byType(ResourceThumbnail), findsOneWidget);
    });

    testWidgets('Campus Ambassador suppresses overlaid title because artwork has baked-in title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: JobThumbnail(
              title: 'Campus Ambassador Program',
              categorySlug: 'campus-brand-promotion',
              size: ThumbnailSize.card,
              width: 340,
              height: 191,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Because hasBakedInTitle is true for campus_ambassador, the text overlay is suppressed
      expect(find.text('Campus Ambassador Program'), findsNothing);
    });
  });
}
