import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/friend_profile_links.dart';

void main() {
  test('builds public friend profile links without a hash route', () {
    final link = friendProfileLinkForCode('abc 123');

    expect(link, 'https://glasstrail.vercel.app/friends/profile/abc%20123');
  });

  test('builds app friend profile links with an explicit route query', () {
    final link = friendProfileAppLinkForCode('abc 123');

    expect(
      link,
      'https://glasstrail.vercel.app/?route=%2Ffriends%2Fprofile%2Fabc%2520123#/friends/profile/abc%20123',
    );
  });
}
