import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/friend_profile_links.dart';

void main() {
  test('builds public friend profile links without a hash route', () {
    final link = friendProfileLinkForCode('abc 123');

    expect(link, 'https://glasstrail.vercel.app/friends/profile/abc%20123');
  });

  test('builds app friend profile links with the Flutter hash route', () {
    final link = friendProfileAppLinkForCode('abc 123');

    expect(link, 'https://glasstrail.vercel.app/#/friends/profile/abc%20123');
  });
}
