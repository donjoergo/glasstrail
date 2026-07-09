import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app_routes.dart';

void main() {
  group('achievement routes', () {
    test('achievementDetailRoute builds the canonical shape', () {
      expect(
        AppRoutes.achievementDetailRoute('occasion_oktoberfest', level: 1, source: 'push_reminder'),
        '/achievements/detail/occasion_oktoberfest?level=1&source=push_reminder',
      );
      expect(
        AppRoutes.achievementDetailRoute('type_beer', level: 100, source: 'in_app'),
        '/achievements/detail/type_beer?level=100&source=in_app',
      );
      expect(
        AppRoutes.achievementDetailRoute('type_beer'),
        '/achievements/detail/type_beer',
      );
    });

    test('isAchievementDetailRoute recognizes detail routes only', () {
      expect(AppRoutes.isAchievementDetailRoute('/achievements/detail/type_beer?level=10'), isTrue);
      expect(AppRoutes.isAchievementDetailRoute('/achievements'), isFalse);
      expect(AppRoutes.isAchievementDetailRoute('/feed'), isFalse);
      expect(AppRoutes.isAchievementDetailRoute(null), isFalse);
    });

    test('achievementDetailFamilyId/Level/Source parse the route', () {
      const route = '/achievements/detail/occasion_oktoberfest?level=1&source=push_reminder';
      expect(AppRoutes.achievementDetailFamilyId(route), 'occasion_oktoberfest');
      expect(AppRoutes.achievementDetailLevel(route), 1);
      expect(AppRoutes.achievementDetailSource(route), 'push_reminder');

      expect(AppRoutes.achievementDetailFamilyId('/achievements/detail/type_beer'), 'type_beer');
      expect(AppRoutes.achievementDetailLevel('/achievements/detail/type_beer'), isNull);
      expect(AppRoutes.achievementDetailSource('/achievements/detail/type_beer'), isNull);
    });

    test('normalize preserves the query string for detail routes only', () {
      const route = '/achievements/detail/type_beer?level=100&source=in_app';
      expect(AppRoutes.normalize(route), route);
      expect(AppRoutes.normalize('/achievements'), '/achievements');
    });

    test('detail routes are explicit post-auth redirects but not restorable', () {
      const route = '/achievements/detail/type_beer?level=100';
      expect(AppRoutes.isExplicitPostAuthRedirectRoute(route), isTrue);
      expect(AppRoutes.isRestorable(route), isFalse);
      expect(AppRoutes.isPostAuthRoute(route), isTrue);
      expect(AppRoutes.postAuthRoute(route), route);
    });

    test('the achievements tab root is a normal restorable home-shell route', () {
      expect(AppRoutes.isRestorable('/achievements'), isTrue);
      expect(AppRoutes.isHomeShellRoute('/achievements'), isTrue);
      expect(AppRoutes.homePrimaryRoute('/achievements'), '/achievements');
      expect(AppRoutes.isPostAuthRoute('/achievements'), isTrue);
    });

    test('home tab index/route mapping includes the achievements tab', () {
      expect(AppRoutes.homeTabIndex('/achievements'), 3);
      expect(AppRoutes.homeRouteForIndex(3), '/achievements');
      expect(AppRoutes.homeTabIndex('/profile'), 4);
      expect(AppRoutes.homeRouteForIndex(4), '/profile');
    });

    test('places is a pushed post-auth route, not restorable', () {
      expect(AppRoutes.isPostAuthRoute('/profile/places'), isTrue);
      expect(AppRoutes.isRestorable('/profile/places'), isFalse);
    });
  });
}
