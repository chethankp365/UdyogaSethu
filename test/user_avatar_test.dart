import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/widgets/user_avatar.dart';

void main() {
  group('UserAvatar Widget Unit & UI Tests', () {
    test('getInitials helper formats uppercase 1-2 letter initials correctly', () {
      expect(getInitials('Mahesh Kumar'), equals('MK'));
      expect(getInitials('Ramesh'), equals('RA'));
      expect(getInitials('A'), equals('A'));
      expect(getInitials(null), equals('US'));
      expect(getInitials(''), equals('US'));
      expect(getInitials('   '), equals('US'));
      expect(getInitials('First Middle Last'), equals('FL'));
    });

    testWidgets('UserAvatar renders fallback initials when avatarPath is null', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                avatarPath: null,
                name: 'Mahesh Kumar',
                radius: 32,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MK'), findsOneWidget);
    });

    testWidgets('UserAvatar renders fallback initials when avatarPath is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                avatarPath: '',
                name: 'Ramesh Sharma',
                radius: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RS'), findsOneWidget);
    });

    testWidgets('UserAvatar handles tap callback when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                avatarPath: null,
                name: 'Test User',
                radius: 30,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UserAvatar));
      expect(tapped, isTrue);
    });
  });
}
