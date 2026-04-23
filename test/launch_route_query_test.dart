import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/launch_route_query.dart';

void main() {
  test('removes the route query parameter without leaving an empty query', () {
    final uri = Uri.parse(
      'https://glasstrail.vercel.app/?route=%2Ffriends%2Fprofile%2Fabc'
      '#/friends/profile/abc',
    );

    expect(
      withoutLaunchRouteQuery(uri).toString(),
      'https://glasstrail.vercel.app/#/friends/profile/abc',
    );
  });

  test('preserves unrelated query parameters and the hash route', () {
    final uri = Uri.parse(
      'https://glasstrail.vercel.app/?utm_source=telegram'
      '&route=%2Ffriends%2Fprofile%2Fabc&utm_medium=share'
      '#/friends/profile/abc',
    );

    expect(
      withoutLaunchRouteQuery(uri).toString(),
      'https://glasstrail.vercel.app/?utm_source=telegram&utm_medium=share'
      '#/friends/profile/abc',
    );
  });

  test('leaves urls without a route query unchanged', () {
    final uri = Uri.parse('https://glasstrail.vercel.app/#/feed');

    expect(withoutLaunchRouteQuery(uri), uri);
  });
}
