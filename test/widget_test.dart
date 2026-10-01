import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/config/env.dart';
import 'package:udyogasethu/main.dart';

void main() {
  testWidgets('App renders MissingEnvScreen directly', (WidgetTester tester) async {
    await tester.pumpWidget(const MissingEnvScreen());
    expect(find.text('Environment Configuration Missing'), findsOneWidget);
  });

  testWidgets('UdyogaSethuApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const UdyogaSethuApp());
    expect(find.byType(UdyogaSethuApp), findsOneWidget);
  });
}
