import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/main.dart';

void main() {
  testWidgets('App renders MissingEnvScreen when env is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UdyogaSethuApp());
    expect(find.text('Environment Configuration Missing'), findsOneWidget);
  });
}
