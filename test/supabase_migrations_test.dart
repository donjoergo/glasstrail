import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _notificationMigrationPath =
    'supabase/migrations/202604280001_add_friend_notifications.sql';
const _feedCheersMigrationPath =
    'supabase/migrations/202605060001_add_feed_entry_cheers.sql';
const _supersededNotificationMigrationPaths = <String>[
  'supabase/migrations/202604250001_add_friend_notifications.sql',
  'supabase/migrations/202604260001_generalize_notifications.sql',
  'supabase/migrations/202604270001_add_friend_notification_static_images.sql',
  'supabase/migrations/202604270002_stabilize_friend_notifications.sql',
  'supabase/migrations/202604280001_fix_notification_static_image_paths.sql',
  'supabase/migrations/202605040001_delete_friend_drink_notifications_with_entries.sql',
];

void main() {
  test('allows pending-request profile media access', () {
    final migration = File(
      'supabase/migrations/202604170001_add_friend_profile_links.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains(
        'create policy "Users can read own and friends media"\n'
        'on storage.objects',
      ),
    );
    expect(
      migration,
      contains("where relationships.status in ('pending', 'accepted')"),
    );
    expect(
      migration,
      contains(
        "relationships.addressee_id = coalesce((storage.foldername(name))[1], '')::uuid",
      ),
    );
    expect(
      migration,
      contains(
        "relationships.requester_id = coalesce((storage.foldername(name))[1], '')::uuid",
      ),
    );
  });

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
    expect(migration, contains("'drinkId', new.source_drink_id"));
    expect(migration, contains("'drinkName', new.drink_name"));
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
    expect(
      migration,
      contains("nullif(btrim(profiles.profile_image_path), '')"),
    );
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
    expect(migration, contains("delete from public.notifications"));
    expect(migration, contains("where type = 'friend_drink_logged'"));
    expect(migration, contains("and sender_user_id = old.user_id"));
    expect(migration, contains("and metadata ->> 'entryId' = old.id::text"));
  });

  test('updates friend drink notifications when entries are edited', () {
    final migration = File(
      'supabase/migrations/202604290001_add_social_feed_drink_notifications.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains(
        'create trigger friend_drink_logged_notifications_update\n'
        'after update on public.drink_entries',
      ),
    );
    expect(migration, contains('update public.notifications'));
    expect(
      migration,
      contains("set sender_display_name = current_sender_display_name"),
    );
    expect(migration, contains('template_args = notification_template_args'));
    expect(migration, contains("'drinkId', new.source_drink_id"));
    expect(migration, contains("'drinkName', new.drink_name"));
    expect(
      migration,
      contains(
        "image_path = public.notification_image_path_for_type(\n"
        "        'friend_drink_logged',\n"
        '        notification_image_path\n'
        '      )',
      ),
    );
    expect(migration, contains("and metadata ->> 'entryId' = old.id::text"));
  });

  test('removes friend drink notifications when friendships are removed', () {
    final migration = File(
      'supabase/migrations/202604290001_add_social_feed_drink_notifications.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('create or replace function public.remove_friend'),
    );
    expect(migration, contains("where type = 'friend_drink_logged'"));
    expect(
      migration,
      contains(
        '(recipient_user_id = requesting_user_id and sender_user_id = target_friend_user_id)',
      ),
    );
    expect(
      migration,
      contains(
        '(recipient_user_id = target_friend_user_id and sender_user_id = requesting_user_id)',
      ),
    );
    expect(migration, contains("'friend_removed'"));
  });

  test('adds the cheers table and cheers rpc in a new migration', () {
    final migration = File(_feedCheersMigrationPath).readAsStringSync();

    expect(
      migration,
      contains('create table if not exists public.drink_entry_cheers'),
    );
    expect(migration, contains('primary key (entry_id, user_id)'));
    expect(
      migration,
      contains('references public.drink_entries(id) on delete cascade'),
    );
    expect(
      migration,
      contains('create or replace function public.set_feed_entry_cheers'),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.set_feed_entry_cheers(uuid, boolean) to authenticated',
      ),
    );
  });

  test('remaps static notification art for accepted requests and cheers', () {
    final migration = File(_feedCheersMigrationPath).readAsStringSync();

    expect(
      migration,
      contains(
        'https://glasstrail.vercel.app/notification-assets/request_accepted.png',
      ),
    );
    expect(
      migration,
      contains('https://glasstrail.vercel.app/notification-assets/cheers.png'),
    );
    expect(migration, contains("when 'friend_drink_cheered' then"));
    expect(migration, contains('update public.notifications'));
  });

  test('extends the feed rpc with cheers aggregates', () {
    final migration = File(_feedCheersMigrationPath).readAsStringSync();

    expect(
      migration,
      contains('create or replace function public.load_feed_drink_posts'),
    );
    expect(migration, contains('cheers_count integer'));
    expect(migration, contains('has_current_user_cheered boolean'));
    expect(
      migration,
      contains(
        'select count(*)::integer\n      from public.drink_entry_cheers cheers',
      ),
    );
    expect(migration, contains('and cheers.user_id = requesting_user_id'));
  });

  test('validates and cleans up cheers in the cheers migration', () {
    final migration = File(_feedCheersMigrationPath).readAsStringSync();

    expect(
      migration,
      contains("raise exception 'The cheers could not be updated.'"),
    );
    expect(migration, contains('entry_owner_user_id = requesting_user_id'));
    expect(migration, contains("relationships.status = 'accepted'"));
    expect(migration, contains("perform public.create_friend_notification("));
    expect(migration, contains("'friend_drink_cheered'"));
    expect(
      migration,
      contains(
        'create trigger friend_drink_cheered_notifications_cleanup\n'
        'after delete on public.drink_entries',
      ),
    );
    expect(
      migration,
      contains(
        'create trigger cleanup_feed_cheers_for_deleted_friendship\n'
        'after delete on public.friend_relationships',
      ),
    );
    expect(
      migration,
      contains(
        'delete from public.drink_entry_cheers cheers\n  using public.drink_entries entries',
      ),
    );
    expect(
      migration,
      contains("metadata ->> 'entryId' = target_entry_id::text"),
    );
  });
}
