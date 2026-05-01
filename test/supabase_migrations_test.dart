import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _notificationMigrationPath =
    'supabase/migrations/202604280001_add_friend_notifications.sql';
const _supersededNotificationMigrationPaths = <String>[
  'supabase/migrations/202604250001_add_friend_notifications.sql',
  'supabase/migrations/202604260001_generalize_notifications.sql',
  'supabase/migrations/202604270001_add_friend_notification_static_images.sql',
  'supabase/migrations/202604270002_stabilize_friend_notifications.sql',
  'supabase/migrations/202604280001_fix_notification_static_image_paths.sql',
];

void main() {
  test('qualifies notification read update columns', () {
    final migration = File(_notificationMigrationPath).readAsStringSync();

    expect(migration, contains('update public.notifications as n'));
    expect(migration, contains('set read_at = coalesce(n.read_at, now())'));
    expect(
      migration,
      contains('where n.recipient_user_id = requesting_user_id'),
    );
    expect(migration, contains('and n.id = any(notification_ids)'));
  });

  test('keeps static image helper in notification creation path', () {
    final migration = File(_notificationMigrationPath).readAsStringSync();

    expect(
      migration,
      contains(
        'public.notification_image_path_for_type(\n'
        '      normalized_notification_type,\n'
        '      notification_image_path\n'
        '    )',
      ),
    );
    expect(
      migration,
      contains(
        "when 'friend_request_accepted' then "
        "'https://glasstrail.vercel.app/notification-assets/cheers.png'",
      ),
    );
    expect(migration, isNot(contains('glasstrail-git-codex')));
  });

  test('ships friend notifications in consolidated migration', () {
    expect(File(_notificationMigrationPath).existsSync(), isTrue);

    for (final path in _supersededNotificationMigrationPaths) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}
