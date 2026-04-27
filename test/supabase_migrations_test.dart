import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('qualifies notification read update columns', () {
    final migration = File(
      'supabase/migrations/202604270002_stabilize_friend_notifications.sql',
    ).readAsStringSync();

    expect(migration, contains('update public.notifications as n'));
    expect(migration, contains('set read_at = coalesce(n.read_at, now())'));
    expect(
      migration,
      contains('where n.recipient_user_id = requesting_user_id'),
    );
    expect(migration, contains('and n.id = any(notification_ids)'));
  });
}
