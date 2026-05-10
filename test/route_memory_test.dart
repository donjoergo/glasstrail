import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/route_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('opens explicit friend profile links after logout', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();
    final friendRoute = AppRoutes.friendProfileRoute('share-code');

    await routeMemory.markLoggedOut();

    expect(routeMemory.resolveInitialRoute(friendRoute), friendRoute);
  });

  test('returns to explicit friend profile links after auth', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();
    final friendRoute = AppRoutes.friendProfileRoute('share-code');

    await routeMemory.markLoggedOut();

    expect(await routeMemory.consumePostAuthRoute(friendRoute), friendRoute);
    expect(routeMemory.lastRoute, friendRoute);
  });

  test('opens explicit friend stats links after logout', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();
    final friendStatsRoute = AppRoutes.friendStatsProfileRoute('friend-user');

    await routeMemory.markLoggedOut();

    expect(routeMemory.resolveInitialRoute(friendStatsRoute), friendStatsRoute);
  });

  test('returns to explicit friend stats links after auth', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();
    final friendStatsRoute = AppRoutes.friendStatsProfileRoute('friend-user');

    await routeMemory.markLoggedOut();

    expect(
      await routeMemory.consumePostAuthRoute(friendStatsRoute),
      friendStatsRoute,
    );
    expect(routeMemory.lastRoute, friendStatsRoute);
  });

  test('keeps feed as the post-auth route after normal logout', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();

    await routeMemory.markLoggedOut();

    expect(routeMemory.resolveInitialRoute(AppRoutes.feed), AppRoutes.auth);
    expect(await routeMemory.consumePostAuthRoute(null), AppRoutes.feed);
  });

  test('ignores normal protected redirects after logout', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();

    await routeMemory.markLoggedOut();

    expect(routeMemory.resolveInitialRoute(AppRoutes.profile), AppRoutes.auth);
    expect(
      await routeMemory.consumePostAuthRoute(AppRoutes.profile),
      AppRoutes.feed,
    );
  });

  test('does not restore notifications as the cold-start route', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'glasstrail.last_route': AppRoutes.notifications,
    });
    final routeMemory = await RouteMemory.create();

    expect(routeMemory.lastRoute, AppRoutes.feed);
    expect(routeMemory.resolveInitialRoute(AppRoutes.root), AppRoutes.feed);
  });

  test('does not remember add-drink or edit-profile routes', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();

    await routeMemory.rememberRoute(AppRoutes.statisticsMap);
    await routeMemory.rememberRoute(AppRoutes.addDrink);
    await routeMemory.rememberRoute(AppRoutes.editProfile);

    expect(routeMemory.lastRoute, AppRoutes.statisticsMap);
  });

  test('still returns explicit secondary routes after auth', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final routeMemory = await RouteMemory.create();

    expect(
      await routeMemory.consumePostAuthRoute(AppRoutes.editProfile),
      AppRoutes.editProfile,
    );
    expect(routeMemory.lastRoute, AppRoutes.feed);
  });
}
