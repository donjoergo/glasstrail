import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAppRepository', () {
    late LocalAppRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = LocalAppRepository(await SharedPreferences.getInstance());
    });

    test('keeps custom drinks and entries isolated per user', () async {
      final userOne = await repository.signUp(
        email: 'one@example.com',
        password: 'secret',
        displayName: 'User One',
      );
      await repository.saveCustomDrink(
        userId: userOne.id,
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
      );
      await repository.addDrinkEntry(
        user: userOne,
        drink: DrinkDefinition(
          id: 'office-brew',
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
          ownerUserId: userOne.id,
        ),
      );
      await repository.signOut();

      final userTwo = await repository.signUp(
        email: 'two@example.com',
        password: 'secret',
        displayName: 'User Two',
      );

      final userOneDrinks = await repository.loadCustomDrinks(userOne.id);
      final userTwoDrinks = await repository.loadCustomDrinks(userTwo.id);
      final userOneEntries = await repository.loadEntries(userOne.id);
      final userTwoEntries = await repository.loadEntries(userTwo.id);

      expect(userOneDrinks, hasLength(1));
      expect(userTwoDrinks, isEmpty);
      expect(userOneEntries, hasLength(1));
      expect(userTwoEntries, isEmpty);
    });

    test(
      'deletes only the selected custom drink and keeps existing entries',
      () async {
        final user = await repository.signUp(
          email: 'delete-custom@example.com',
          password: 'secret',
          displayName: 'Delete Custom User',
        );

        final first = await repository.saveCustomDrink(
          userId: user.id,
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
        );
        await repository.saveCustomDrink(
          userId: user.id,
          name: 'Night Cap',
          category: DrinkCategory.cocktails,
          volumeMl: 200,
        );
        await repository.addDrinkEntry(
          user: user,
          drink: first,
          volumeMl: first.volumeMl,
        );

        await repository.deleteCustomDrink(userId: user.id, drink: first);

        final restoredDrinks = await repository.loadCustomDrinks(user.id);
        final restoredEntries = await repository.loadEntries(user.id);
        expect(restoredDrinks, hasLength(1));
        expect(restoredDrinks.single.name, 'Night Cap');
        expect(restoredEntries, hasLength(1));
        expect(restoredEntries.single.drinkName, 'Office Brew');
      },
    );

    test('restores the active session and rejects duplicate emails', () async {
      final user = await repository.signUp(
        email: 'duplicate@example.com',
        password: 'secret',
        displayName: 'Duplicate',
      );

      final restored = await repository.restoreSession();

      expect(restored?.id, user.id);
      expect(
        () => repository.signUp(
          email: 'duplicate@example.com',
          password: 'secret',
          displayName: 'Duplicate Two',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('persists all settings options for a user', () async {
      final user = await repository.signUp(
        email: 'settings@example.com',
        password: 'secret',
        displayName: 'Settings User',
      );

      await repository.saveSettings(
        user.id,
        const UserSettings(
          themePreference: AppThemePreference.dark,
          localeCode: 'de',
          unit: AppUnit.oz,
          handedness: AppHandedness.left,
          hiddenGlobalDrinkIds: <String>['beer-pils'],
          hiddenGlobalDrinkCategories: <DrinkCategory>[DrinkCategory.wine],
          globalDrinkOrderOverrides: <DrinkCategory, List<String>>{
            DrinkCategory.beer: <String>['beer-ipa', 'beer-pils'],
          },
        ),
      );

      final restored = await repository.loadSettings(user.id);

      expect(restored.themePreference, AppThemePreference.dark);
      expect(restored.localeCode, 'de');
      expect(restored.unit, AppUnit.oz);
      expect(restored.handedness, AppHandedness.left);
      expect(restored.hiddenGlobalDrinkIds, <String>['beer-pils']);
      expect(restored.hiddenGlobalDrinkCategories, <DrinkCategory>[
        DrinkCategory.wine,
      ]);
      expect(restored.globalDrinkOrderOverrides[DrinkCategory.beer], <String>[
        'beer-ipa',
        'beer-pils',
      ]);
    });

    test('creates stable profile links and resolves friend profiles', () async {
      final user = await repository.signUp(
        email: 'profile-link@example.com',
        password: 'secret',
        displayName: 'Profile Link',
      );

      final first = await repository.getOwnFriendProfile(user.id);
      final second = await repository.getOwnFriendProfile(user.id);
      final resolved = await repository.resolveFriendProfileLink(
        first.profileShareCode!,
      );

      expect(first.profileShareCode, isNotEmpty);
      expect(second.profileShareCode, first.profileShareCode);
      expect(resolved.id, user.id);
      expect(resolved.email, 'profile-link@example.com');
    });

    test('resolves public friend profiles without exposing email', () async {
      final user = await repository.signUp(
        email: 'public-profile-link@example.com',
        password: 'secret',
        displayName: 'Public Profile Link',
      );

      final ownProfile = await repository.getOwnFriendProfile(user.id);
      final publicProfile = await repository.resolvePublicFriendProfileLink(
        ownProfile.profileShareCode!,
      );

      expect(publicProfile.id, user.id);
      expect(publicProfile.displayName, 'Public Profile Link');
      expect(publicProfile.toJson(), isNot(contains('email')));
    });

    test(
      'moves friend requests through pending accepted and removed states',
      () async {
        final requester = await repository.signUp(
          email: 'friend-requester@example.com',
          password: 'secret',
          displayName: 'Friend Requester',
        );
        await repository.signOut();
        final addressee = await repository.signUp(
          email: 'friend-addressee@example.com',
          password: 'secret',
          displayName: 'Friend Addressee',
        );
        final addresseeProfile = await repository.getOwnFriendProfile(
          addressee.id,
        );

        final requesterConnections = await repository
            .sendFriendRequestToProfile(
              userId: requester.id,
              shareCode: addresseeProfile.profileShareCode!,
            );

        expect(requesterConnections, hasLength(1));
        expect(requesterConnections.single.profile.id, addressee.id);
        expect(requesterConnections.single.status, FriendRequestStatus.pending);
        expect(
          requesterConnections.single.direction,
          FriendRequestDirection.outgoing,
        );

        final addresseeConnections = await repository.loadFriendConnections(
          addressee.id,
        );
        expect(addresseeConnections.single.profile.id, requester.id);
        expect(
          addresseeConnections.single.direction,
          FriendRequestDirection.incoming,
        );

        final accepted = await repository.acceptFriendRequest(
          userId: addressee.id,
          relationshipId: addresseeConnections.single.id,
        );
        expect(accepted.single.status, FriendRequestStatus.accepted);
        expect(accepted.single.direction, FriendRequestDirection.none);

        final removed = await repository.removeFriend(
          userId: requester.id,
          friendUserId: addressee.id,
        );
        expect(removed, isEmpty);
        expect(await repository.loadFriendConnections(addressee.id), isEmpty);
      },
    );

    test('creates notifications for friendship actions', () async {
      final requester = await repository.signUp(
        email: 'notify-requester@example.com',
        password: 'secret',
        displayName: 'Notify Requester',
        profileImagePath: '/tmp/notify-requester.png',
      );
      await repository.signOut();
      final addressee = await repository.signUp(
        email: 'notify-addressee@example.com',
        password: 'secret',
        displayName: 'Notify Addressee',
      );
      final addresseeProfile = await repository.getOwnFriendProfile(
        addressee.id,
      );

      final requesterConnections = await repository.sendFriendRequestToProfile(
        userId: requester.id,
        shareCode: addresseeProfile.profileShareCode!,
      );

      final addresseeNotifications = await repository.loadNotifications(
        addressee.id,
      );
      expect(addresseeNotifications, hasLength(1));
      expect(
        addresseeNotifications.single.type,
        AppNotificationTypes.friendRequestSent,
      );
      expect(addresseeNotifications.single.senderUserId, requester.id);
      expect(
        addresseeNotifications.single.senderDisplayName,
        'Notify Requester',
      );
      expect(
        addresseeNotifications.single.imagePath,
        '/tmp/notify-requester.png',
      );
      expect(
        addresseeNotifications.single.title('en'),
        lookupAppLocalizations(
          const Locale('en'),
        ).notificationFriendRequestSentTitle('Notify Requester'),
      );
      expect(
        addresseeNotifications.single.title('de'),
        lookupAppLocalizations(
          const Locale('de'),
        ).notificationFriendRequestSentTitle('Notify Requester'),
      );
      expect(
        addresseeNotifications.single.text('en'),
        lookupAppLocalizations(
          const Locale('en'),
        ).notificationFriendRequestSentBody,
      );

      await repository.acceptFriendRequest(
        userId: addressee.id,
        relationshipId: requesterConnections.single.id,
      );
      final requesterNotifications = await repository.loadNotifications(
        requester.id,
      );
      expect(
        requesterNotifications.single.type,
        AppNotificationTypes.friendRequestAccepted,
      );
      expect(requesterNotifications.single.senderUserId, addressee.id);

      await repository.removeFriend(
        userId: requester.id,
        friendUserId: addressee.id,
      );
      final addresseeAfterRemoval = await repository.loadNotifications(
        addressee.id,
      );
      expect(
        addresseeAfterRemoval.first.type,
        AppNotificationTypes.friendRemoved,
      );
      expect(addresseeAfterRemoval.first.senderUserId, requester.id);
    });

    test('creates rejected friend request notifications', () async {
      final requester = await repository.signUp(
        email: 'notify-reject-requester@example.com',
        password: 'secret',
        displayName: 'Reject Requester',
      );
      await repository.signOut();
      final addressee = await repository.signUp(
        email: 'notify-reject-addressee@example.com',
        password: 'secret',
        displayName: 'Reject Addressee',
      );
      final addresseeProfile = await repository.getOwnFriendProfile(
        addressee.id,
      );

      await repository.sendFriendRequestToProfile(
        userId: requester.id,
        shareCode: addresseeProfile.profileShareCode!,
      );
      final addresseeConnections = await repository.loadFriendConnections(
        addressee.id,
      );

      await repository.rejectFriendRequest(
        userId: addressee.id,
        relationshipId: addresseeConnections.single.id,
      );

      final requesterNotifications = await repository.loadNotifications(
        requester.id,
      );
      expect(
        requesterNotifications.single.type,
        AppNotificationTypes.friendRequestRejected,
      );
      expect(requesterNotifications.single.senderUserId, addressee.id);
    });

    test(
      'does not duplicate notifications for existing pending requests',
      () async {
        final requester = await repository.signUp(
          email: 'notify-duplicate-requester@example.com',
          password: 'secret',
          displayName: 'Duplicate Requester',
        );
        await repository.signOut();
        final addressee = await repository.signUp(
          email: 'notify-duplicate-addressee@example.com',
          password: 'secret',
          displayName: 'Duplicate Addressee',
        );
        final addresseeProfile = await repository.getOwnFriendProfile(
          addressee.id,
        );

        await repository.sendFriendRequestToProfile(
          userId: requester.id,
          shareCode: addresseeProfile.profileShareCode!,
        );
        await repository.sendFriendRequestToProfile(
          userId: requester.id,
          shareCode: addresseeProfile.profileShareCode!,
        );

        expect(await repository.loadNotifications(addressee.id), hasLength(1));
      },
    );

    test('marks notifications as read', () async {
      final requester = await repository.signUp(
        email: 'notify-read-requester@example.com',
        password: 'secret',
        displayName: 'Read Requester',
      );
      await repository.signOut();
      final addressee = await repository.signUp(
        email: 'notify-read-addressee@example.com',
        password: 'secret',
        displayName: 'Read Addressee',
      );
      final addresseeProfile = await repository.getOwnFriendProfile(
        addressee.id,
      );

      await repository.sendFriendRequestToProfile(
        userId: requester.id,
        shareCode: addresseeProfile.profileShareCode!,
      );
      final notification = (await repository.loadNotifications(
        addressee.id,
      )).single;

      expect(notification.isUnread, isTrue);

      final updated = await repository.markNotificationsRead(
        userId: addressee.id,
        notificationIds: <String>[notification.id],
      );

      expect(updated.single.isRead, isTrue);
      expect(updated.single.readAt, isNotNull);
    });

    test('withdraws outgoing pending friend requests', () async {
      final requester = await repository.signUp(
        email: 'withdraw-requester@example.com',
        password: 'secret',
        displayName: 'Withdraw Requester',
      );
      await repository.signOut();
      final addressee = await repository.signUp(
        email: 'withdraw-addressee@example.com',
        password: 'secret',
        displayName: 'Withdraw Addressee',
      );
      final addresseeProfile = await repository.getOwnFriendProfile(
        addressee.id,
      );

      final requesterConnections = await repository.sendFriendRequestToProfile(
        userId: requester.id,
        shareCode: addresseeProfile.profileShareCode!,
      );

      final withdrawn = await repository.cancelFriendRequest(
        userId: requester.id,
        relationshipId: requesterConnections.single.id,
      );

      expect(withdrawn, isEmpty);
      expect(await repository.loadFriendConnections(addressee.id), isEmpty);
    });

    test('rejects self friend requests', () async {
      final user = await repository.signUp(
        email: 'self-friend@example.com',
        password: 'secret',
        displayName: 'Self Friend',
      );
      final profile = await repository.getOwnFriendProfile(user.id);

      expect(
        () => repository.sendFriendRequestToProfile(
          userId: user.id,
          shareCode: profile.profileShareCode!,
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('updates only comment and image for an existing entry', () async {
      final user = await repository.signUp(
        email: 'update-entry@example.com',
        password: 'secret',
        displayName: 'Update Entry User',
      );

      final created = await repository.addDrinkEntry(
        user: user,
        drink: const DrinkDefinition(
          id: 'water',
          name: 'Water',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 250,
        ),
        volumeMl: 250,
        comment: 'Before',
        imagePath: '/tmp/before.png',
        locationLatitude: 52.52,
        locationLongitude: 13.405,
        locationAddress: 'Alexanderplatz 1, 10178 Berlin',
        consumedAt: DateTime(2026, 3, 19, 10, 30),
      );

      final updated = await repository.updateDrinkEntry(
        user: user,
        entry: created,
        comment: 'After',
        imagePath: '/tmp/after.png',
      );

      expect(updated.drinkId, created.drinkId);
      expect(updated.drinkName, created.drinkName);
      expect(updated.category, created.category);
      expect(updated.volumeMl, created.volumeMl);
      expect(updated.consumedAt, created.consumedAt);
      expect(updated.comment, 'After');
      expect(updated.imagePath, '/tmp/after.png');
      expect(updated.locationLatitude, 52.52);
      expect(updated.locationLongitude, 13.405);
      expect(updated.locationAddress, 'Alexanderplatz 1, 10178 Berlin');
    });

    test('persists location fields for a drink entry', () async {
      final user = await repository.signUp(
        email: 'location-entry@example.com',
        password: 'secret',
        displayName: 'Location Entry User',
      );

      await repository.addDrinkEntry(
        user: user,
        drink: const DrinkDefinition(
          id: 'pils',
          name: 'Pils',
          category: DrinkCategory.beer,
        ),
        locationLatitude: 48.137,
        locationLongitude: 11.575,
        locationAddress: 'Marienplatz 1, 80331 Munich',
      );

      final restored = await repository.loadEntries(user.id);

      expect(restored.single.locationLatitude, 48.137);
      expect(restored.single.locationLongitude, 11.575);
      expect(restored.single.locationAddress, 'Marienplatz 1, 80331 Munich');
    });

    test('persists import metadata for a drink entry', () async {
      final user = await repository.signUp(
        email: 'import-entry@example.com',
        password: 'secret',
        displayName: 'Import Entry User',
      );

      await repository.addDrinkEntry(
        user: user,
        drink: const DrinkDefinition(
          id: 'beer-classic',
          name: 'Beer',
          category: DrinkCategory.beer,
          volumeMl: 500,
        ),
        consumedAt: DateTime(2022, 6, 6, 22, 55, 15),
        importSource: 'beer_with_me',
        importSourceId: '172120176',
      );

      final restored = await repository.loadEntries(user.id);

      expect(restored.single.importSource, 'beer_with_me');
      expect(restored.single.importSourceId, '172120176');
    });

    test(
      'normalizes empty entry comments to null and removes images',
      () async {
        final user = await repository.signUp(
          email: 'clear-entry@example.com',
          password: 'secret',
          displayName: 'Clear Entry User',
        );

        final created = await repository.addDrinkEntry(
          user: user,
          drink: const DrinkDefinition(
            id: 'cola',
            name: 'Cola',
            category: DrinkCategory.nonAlcoholic,
          ),
          comment: 'Has comment',
          imagePath: '/tmp/image.png',
        );

        final updated = await repository.updateDrinkEntry(
          user: user,
          entry: created,
          comment: '   ',
          imagePath: null,
        );

        expect(updated.comment, isNull);
        expect(updated.imagePath, isNull);
        final restored = await repository.loadEntries(user.id);
        expect(restored.single.comment, isNull);
        expect(restored.single.imagePath, isNull);
      },
    );

    test('deletes only the selected entry for a user', () async {
      final user = await repository.signUp(
        email: 'delete-selected@example.com',
        password: 'secret',
        displayName: 'Delete Selected User',
      );

      final first = await repository.addDrinkEntry(
        user: user,
        drink: const DrinkDefinition(
          id: 'pils',
          name: 'Pils',
          category: DrinkCategory.beer,
        ),
      );
      await repository.addDrinkEntry(
        user: user,
        drink: const DrinkDefinition(
          id: 'water',
          name: 'Water',
          category: DrinkCategory.nonAlcoholic,
        ),
      );

      await repository.deleteDrinkEntry(userId: user.id, entry: first);

      final restored = await repository.loadEntries(user.id);
      expect(restored, hasLength(1));
      expect(restored.single.id, isNot(first.id));
    });
  });
}
