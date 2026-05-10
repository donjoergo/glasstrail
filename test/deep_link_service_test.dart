import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/deep_link_service.dart';

void main() {
  test('maps public profile paths to friend profile routes', () {
    final route = routeFromDeepLink(
      Uri.parse('https://glasstrail.vercel.app/friends/profile/abc%20123'),
    );

    expect(route, AppRoutes.friendProfileRoute('abc 123'));
  });

  test('maps route query links to friend profile routes', () {
    final route = routeFromDeepLink(
      Uri.parse(
        'https://glasstrail.vercel.app/?route=%2Ffriends%2Fprofile%2Fabc%2520123'
        '#/friends/profile/abc%20123',
      ),
    );

    expect(route, AppRoutes.friendProfileRoute('abc 123'));
  });

  test('maps hash routes to app routes', () {
    final route = routeFromDeepLink(
      Uri.parse('https://glasstrail.vercel.app/#/friends/profile/abc%20123'),
    );

    expect(route, AppRoutes.friendProfileRoute('abc 123'));
  });

  test('ignores unknown deep links', () {
    final route = routeFromDeepLink(
      Uri.parse('https://glasstrail.vercel.app/unknown/path'),
    );

    expect(route, isNull);
  });
}
