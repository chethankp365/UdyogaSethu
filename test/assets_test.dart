import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:udyogasethu/core/widgets/dev_assets_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DevAssetsScreen renders all logo and vector assets without throwing error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DevAssetsScreen(),
      ),
    );

    expect(find.byType(DevAssetsScreen), findsOneWidget);
    expect(find.text('Asset Gallery (/dev/assets)'), findsOneWidget);

    // Verify Image.asset widgets (logo.png, logo_small.png)
    expect(find.byType(Image), findsNWidgets(2));

    // Verify SvgPicture widgets (splash, intro, 3 features, 3 roles, 2 empty states = 10 SVGs)
    expect(find.byType(SvgPicture), findsNWidgets(10));
  });
}
