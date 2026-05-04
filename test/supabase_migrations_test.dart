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
  'supabase/migrations/202605040001_delete_friend_drink_notifications_with_entries.sql',
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
    expect(
      migration,
      contains(
        'https://glasstrail.vercel.app/notification-assets/request_rejected.png',
      ),
    );
    expect(
      migration,
      contains(
        'https://glasstrail.vercel.app/notification-assets/friend_removed.png',
      ),
    );
    expect(migration, isNot(contains('notification-assets/sad.jpg')));
    expect(migration, isNot(contains('glasstrail-git-codex')));
  });

  test('ships friend notifications in consolidated migration', () {
    expect(File(_notificationMigrationPath).existsSync(), isTrue);

    for (final path in _supersededNotificationMigrationPaths) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('adds social feed rpc with friend access and cursor ordering', () {
    final migration = File(
      'supabase/migrations/202604290001_add_social_feed_drink_notifications.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('create or replace function public.load_feed_drink_posts'),
    );
    expect(migration, contains("where relationships.status = 'accepted'"));
    expect(migration, contains('entries.user_id = requesting_user_id'));
    expect(
      migration,
      contains('order by entries.consumed_at desc, entries.id desc'),
    );
    expect(migration, contains('entries.consumed_at < cursor_consumed_at'));
    expect(migration, contains('and entries.id < cursor_id'));
    expect(migration, contains('limit sanitized_page_limit + 1'));
    expect(
      migration,
      contains(
        'grant execute on function public.load_feed_drink_posts(integer, timestamptz, uuid) to authenticated',
      ),
    );
  });

  test('adds friend drink notifications with import suppression', () {
    final migration = File(
      'supabase/migrations/202604290001_add_social_feed_drink_notifications.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains(
        'create trigger friend_drink_logged_notifications\n'
        'after insert on public.drink_entries',
      ),
    );
    expect(
      migration,
      contains(
        "or nullif(btrim(coalesce(new.import_source, '')), '') is not null",
      ),
    );
    expect(migration, contains("relationships.status = 'accepted'"));
    expect(migration, contains("'friend_drink_logged'"));
    expect(migration, contains("'entryId', new.id, 'route', '/feed'"));
  });

  test('extends notification image mappings without changing old friend art', () {
    final migration = File(
      'supabase/migrations/202604290001_add_social_feed_drink_notifications.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('https://glasstrail.vercel.app/notification-assets/cheers.png'),
    );
    expect(
      migration,
      contains(
        'https://glasstrail.vercel.app/notification-assets/request_rejected.png',
      ),
    );
    expect(
      migration,
      contains(
        'https://glasstrail.vercel.app/notification-assets/friend_removed.png',
      ),
    );
    expect(
      migration,
      contains(
        'https://glasstrail.vercel.app/notification-assets/app-icon.png',
      ),
    );
    expect(migration, isNot(contains('notification-assets/sad.jpg')));
    expect(migration, contains("when 'friend_drink_logged' then coalesce"));
    expect(migration, contains("nullif(btrim(new.image_path), '')"));
    expect(migration, contains("nullif(btrim(custom_drink_image_path), '')"));
  });

  test('removes friend drink notifications when entries are deleted', () {
    final migration = File(
      'supabase/migrations/202604290001_add_social_feed_drink_notifications.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains(
        'create trigger friend_drink_logged_notifications_cleanup\n'
        'after delete on public.drink_entries',
      ),
    );
    expect(
      migration,
      contains("delete from public.notifications"),
    );
    expect(migration, contains("where type = 'friend_drink_logged'"));
    expect(migration, contains("and sender_user_id = old.user_id"));
    expect(migration, contains("and metadata ->> 'entryId' = old.id::text"));
  });
}
