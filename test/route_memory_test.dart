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
}
