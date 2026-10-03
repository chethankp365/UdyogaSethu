import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyogasethu/core/router/app_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSessionNotifier State Transition Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial status defaults to booting with seeker activeRole', () {
      final session = container.read(appSessionProvider);
      expect(session.status, AuthSessionStatus.booting);
      expect(session.activeRole, UserRole.seeker);
    });

    test('Updating status to needsOnboarding modifies state correctly', () {
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.needsOnboarding);

      expect(container.read(appSessionProvider).status, AuthSessionStatus.needsOnboarding);
    });

    test('Updating status to signedOut modifies state correctly', () {
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.signedOut);

      expect(container.read(appSessionProvider).status, AuthSessionStatus.signedOut);
    });

    test('Updating status to needsRole modifies state correctly', () {
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.needsRole);

      expect(container.read(appSessionProvider).status, AuthSessionStatus.needsRole);
    });

    test('Updating status to needsProfile with provider role updates state', () {
      final notifier = container.read(appSessionProvider.notifier);
      notifier.updateSession(
        status: AuthSessionStatus.needsProfile,
        role: UserRole.provider,
      );

      final session = container.read(appSessionProvider);
      expect(session.status, AuthSessionStatus.needsProfile);
      expect(session.activeRole, UserRole.provider);
    });

    test('Updating status to suspended modifies state correctly', () {
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setSessionStatus(AuthSessionStatus.suspended);

      expect(container.read(appSessionProvider).status, AuthSessionStatus.suspended);
    });

    test('Capturing and clearing pending deep link behaves correctly', () {
      final notifier = container.read(appSessionProvider.notifier);
      notifier.setDeepLinkPending('/seeker/jobs');

      expect(container.read(appSessionProvider).deepLinkPending, '/seeker/jobs');

      notifier.setDeepLinkPending(null);
      expect(container.read(appSessionProvider).deepLinkPending, null);
    });

    test('getHomeForRole returns correct route for each UserRole', () {
      expect(AppSessionNotifier.getHomeForRole(UserRole.seeker), '/seeker/home');
      expect(AppSessionNotifier.getHomeForRole(UserRole.provider), '/provider/home');
      expect(AppSessionNotifier.getHomeForRole(UserRole.farmer), '/farmer/home');
    });
  });
}
