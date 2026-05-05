import 'dart:convert';

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
        addresseeNotifications.single.templateArgs['senderDisplayName'],
        'Notify Requester',
      );
      expect(
        addresseeNotifications.single.title(
          lookupAppLocalizations(const Locale('en')),
        ),
        lookupAppLocalizations(
          const Locale('en'),
        ).notificationFriendRequestSentTitle('Notify Requester'),
      );
      expect(
        addresseeNotifications.single.title(
          lookupAppLocalizations(const Locale('de')),
        ),
        lookupAppLocalizations(
          const Locale('de'),
        ).notificationFriendRequestSentTitle('Notify Requester'),
      );
      expect(
        addresseeNotifications.single.text(
          lookupAppLocalizations(const Locale('en')),
        ),
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
      expect(
        requesterNotifications.single.imagePath,
        AppNotificationImageUrls.cheers,
      );

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
      expect(
        addresseeAfterRemoval.first.imagePath,
        AppNotificationImageUrls.friendRemoved,
      );
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
      expect(
        requesterNotifications.single.imagePath,
        AppNotificationImageUrls.requestRejected,
      );
    });

    test(
      'loads own and accepted friend feed posts newest first with pagination',
      () async {
        final user = await repository.signUp(
          email: 'feed-owner@example.com',
          password: 'secret',
          displayName: 'Feed Owner',
        );
        await repository.signOut();
        final friend = await repository.signUp(
          email: 'feed-friend@example.com',
          password: 'secret',
          displayName: 'Feed Friend',
        );
        await repository.signOut();
        final stranger = await repository.signUp(
          email: 'feed-stranger@example.com',
          password: 'secret',
          displayName: 'Feed Stranger',
        );

        final friendProfile = await repository.getOwnFriendProfile(friend.id);
        final userConnections = await repository.sendFriendRequestToProfile(
          userId: user.id,
          shareCode: friendProfile.profileShareCode!,
        );
        await repository.acceptFriendRequest(
          userId: friend.id,
          relationshipId: userConnections.single.id,
        );

        final drink = (await repository.loadDefaultCatalog()).firstWhere(
          (candidate) => candidate.id == 'beer-pils',
        );
        final baseTime = DateTime(2026, 4, 29, 20);
        await repository.addDrinkEntry(
          user: user,
          drink: drink,
          consumedAt: baseTime.subtract(const Duration(minutes: 1)),
        );
        await repository.addDrinkEntry(
          user: friend,
          drink: drink,
          consumedAt: baseTime,
        );
        await repository.addDrinkEntry(
          user: stranger,
          drink: drink,
          consumedAt: baseTime.add(const Duration(minutes: 1)),
        );

        final page = await repository.loadFeedDrinkPosts(
          userId: user.id,
          limit: 1,
        );
        final nextPage = await repository.loadFeedDrinkPosts(
          userId: user.id,
          cursor: page.cursor,
          limit: 1,
        );

        expect(page.posts, hasLength(1));
        expect(page.posts.single.authorProfile.id, friend.id);
        expect(page.posts.single.isOwnEntry, isFalse);
        expect(page.hasMore, isTrue);
        expect(nextPage.posts, hasLength(1));
        expect(nextPage.posts.single.authorProfile.id, user.id);
        expect(nextPage.posts.single.isOwnEntry, isTrue);
        expect(nextPage.hasMore, isFalse);
        expect(
          <FeedDrinkPost>[
            ...page.posts,
            ...nextPage.posts,
          ].map((post) => post.authorProfile.id),
          isNot(contains(stranger.id)),
        );
      },
    );

    test('paginates feed posts twenty at a time', () async {
      final user = await repository.signUp(
        email: 'feed-page-owner@example.com',
        password: 'secret',
        displayName: 'Feed Page Owner',
      );
      final drink = (await repository.loadDefaultCatalog()).firstWhere(
        (candidate) => candidate.id == 'beer-pils',
      );
      final baseTime = DateTime(2026, 4, 29, 20);
      for (var index = 0; index < 25; index++) {
        await repository.addDrinkEntry(
          user: user,
          drink: drink,
          consumedAt: baseTime.subtract(Duration(minutes: index)),
        );
      }

      final firstPage = await repository.loadFeedDrinkPosts(userId: user.id);
      final secondPage = await repository.loadFeedDrinkPosts(
        userId: user.id,
        cursor: firstPage.cursor,
      );

      expect(firstPage.posts, hasLength(20));
      expect(firstPage.hasMore, isTrue);
      expect(firstPage.cursor, isNotNull);
      expect(secondPage.posts, hasLength(5));
      expect(secondPage.hasMore, isFalse);
      expect(
        firstPage.posts
            .map((post) => post.entry.id)
            .toSet()
            .intersection(
              secondPage.posts.map((post) => post.entry.id).toSet(),
            ),
        isEmpty,
      );
    });

    test('creates drink logged notifications for accepted friends', () async {
      final friend = await repository.signUp(
        email: 'drink-notify-friend@example.com',
        password: 'secret',
        displayName: 'Drink Notify Friend',
      );
      await repository.signOut();
      final logger = await repository.signUp(
        email: 'drink-notify-logger@example.com',
        password: 'secret',
        displayName: 'Drink Notify Logger',
      );
      final loggerProfile = await repository.getOwnFriendProfile(logger.id);
      final friendConnections = await repository.sendFriendRequestToProfile(
        userId: friend.id,
        shareCode: loggerProfile.profileShareCode!,
      );
      await repository.acceptFriendRequest(
        userId: logger.id,
        relationshipId: friendConnections.single.id,
      );

      final drink = (await repository.loadDefaultCatalog()).firstWhere(
        (candidate) => candidate.id == 'beer-pils',
      );
      await repository.addDrinkEntry(
        user: logger,
        drink: drink,
        comment: 'Cheers from the park',
        imagePath: '/tmp/entry-photo.png',
        locationAddress: 'Park Street 1',
      );

      final notifications = await repository.loadNotifications(friend.id);
      final drinkNotification = notifications.firstWhere(
        (notification) =>
            notification.type == AppNotificationTypes.friendDrinkLogged,
      );

      expect(drinkNotification.senderUserId, logger.id);
      expect(drinkNotification.imagePath, '/tmp/entry-photo.png');
      expect(drinkNotification.templateDrinkId, 'beer-pils');
      expect(
        drinkNotification.title(lookupAppLocalizations(const Locale('en'))),
        'Drink Notify Logger drinks Pils',
      );
      expect(
        drinkNotification.text(lookupAppLocalizations(const Locale('en'))),
        '🗨️ Cheers from the park\n📍 Park Street 1',
      );
      expect(drinkNotification.metadata['route'], '/feed');
      expect(drinkNotification.metadata['entryId'], isNotEmpty);
    });

    test(
      'updates existing drink logged notifications when entry details change',
      () async {
        final friend = await repository.signUp(
          email: 'drink-update-friend@example.com',
          password: 'secret',
          displayName: 'Drink Update Friend',
        );
        await repository.signOut();
        final logger = await repository.signUp(
          email: 'drink-update-logger@example.com',
          password: 'secret',
          displayName: 'Drink Update Logger',
          profileImagePath: '/tmp/drink-update-profile.png',
        );
        final loggerProfile = await repository.getOwnFriendProfile(logger.id);
        final friendConnections = await repository.sendFriendRequestToProfile(
          userId: friend.id,
          shareCode: loggerProfile.profileShareCode!,
        );
        await repository.acceptFriendRequest(
          userId: logger.id,
          relationshipId: friendConnections.single.id,
        );

        final drink = (await repository.loadDefaultCatalog()).firstWhere(
          (candidate) => candidate.id == 'beer-pils',
        );
        final entry = await repository.addDrinkEntry(
          user: logger,
          drink: drink,
          comment: 'Original note',
        );
        final initialNotification =
            (await repository.loadNotifications(friend.id)).firstWhere(
              (notification) =>
                  notification.type == AppNotificationTypes.friendDrinkLogged,
            );
        await repository.markNotificationsRead(
          userId: friend.id,
          notificationIds: [initialNotification.id],
        );

        await repository.updateDrinkEntry(
          user: logger,
          entry: entry,
          comment: 'Updated note',
          imagePath: '/tmp/updated-entry-photo.png',
        );

        final updatedNotification =
            (await repository.loadNotifications(friend.id)).firstWhere(
              (notification) =>
                  notification.type == AppNotificationTypes.friendDrinkLogged,
            );

        expect(updatedNotification.id, initialNotification.id);
        expect(updatedNotification.isRead, isTrue);
        expect(updatedNotification.templateDrinkId, 'beer-pils');
        expect(updatedNotification.templateDrinkName, 'Pils');
        expect(updatedNotification.templateComment, 'Updated note');
        expect(updatedNotification.imagePath, '/tmp/updated-entry-photo.png');
        expect(updatedNotification.metadata['entryId'], entry.id);

        await repository.updateDrinkEntry(
          user: logger,
          entry: entry.copyWith(
            comment: 'Updated note',
            imagePath: '/tmp/updated-entry-photo.png',
          ),
          comment: 'Updated note',
          imagePath: null,
        );

        final fallbackNotification =
            (await repository.loadNotifications(friend.id)).firstWhere(
              (notification) =>
                  notification.type == AppNotificationTypes.friendDrinkLogged,
            );
        expect(fallbackNotification.id, initialNotification.id);
        expect(fallbackNotification.isRead, isTrue);
        expect(fallbackNotification.imagePath, '/tmp/drink-update-profile.png');
      },
    );

    test(
      'deletes only the corresponding drink logged notification with the entry',
      () async {
        final friend = await repository.signUp(
          email: 'drink-delete-friend@example.com',
          password: 'secret',
          displayName: 'Drink Delete Friend',
        );
        await repository.signOut();
        final logger = await repository.signUp(
          email: 'drink-delete-logger@example.com',
          password: 'secret',
          displayName: 'Drink Delete Logger',
        );
        final loggerProfile = await repository.getOwnFriendProfile(logger.id);
        final friendConnections = await repository.sendFriendRequestToProfile(
          userId: friend.id,
          shareCode: loggerProfile.profileShareCode!,
        );
        await repository.acceptFriendRequest(
          userId: logger.id,
          relationshipId: friendConnections.single.id,
        );

        final drink = (await repository.loadDefaultCatalog()).firstWhere(
          (candidate) => candidate.id == 'beer-pils',
        );
        final firstEntry = await repository.addDrinkEntry(
          user: logger,
          drink: drink,
          comment: 'First round',
        );
        final secondEntry = await repository.addDrinkEntry(
          user: logger,
          drink: drink,
          comment: 'Second round',
        );

        expect(
          (await repository.loadNotifications(friend.id))
              .where(
                (notification) =>
                    notification.type == AppNotificationTypes.friendDrinkLogged,
              )
              .map((notification) => notification.metadata['entryId'])
              .toSet(),
          {firstEntry.id, secondEntry.id},
        );

        await repository.deleteDrinkEntry(userId: logger.id, entry: firstEntry);

        final remainingNotifications = await repository.loadNotifications(
          friend.id,
        );
        expect(
          remainingNotifications
              .where(
                (notification) =>
                    notification.type == AppNotificationTypes.friendDrinkLogged,
              )
              .map((notification) => notification.metadata['entryId'])
              .toList(growable: false),
          [secondEntry.id],
        );
      },
    );

    test(
      'removes friend drink notifications for both users when unfriending',
      () async {
        final requester = await repository.signUp(
          email: 'unfriend-drink-requester@example.com',
          password: 'secret',
          displayName: 'Unfriend Drink Requester',
        );
        await repository.signOut();
        final addressee = await repository.signUp(
          email: 'unfriend-drink-addressee@example.com',
          password: 'secret',
          displayName: 'Unfriend Drink Addressee',
        );
        final addresseeProfile = await repository.getOwnFriendProfile(
          addressee.id,
        );
        final requesterConnections = await repository
            .sendFriendRequestToProfile(
              userId: requester.id,
              shareCode: addresseeProfile.profileShareCode!,
            );
        await repository.acceptFriendRequest(
          userId: addressee.id,
          relationshipId: requesterConnections.single.id,
        );

        final drink = (await repository.loadDefaultCatalog()).firstWhere(
          (candidate) => candidate.id == 'beer-pils',
        );
        await repository.addDrinkEntry(user: requester, drink: drink);
        await repository.addDrinkEntry(user: addressee, drink: drink);

        expect(
          (await repository.loadNotifications(requester.id)).any(
            (notification) =>
                notification.type == AppNotificationTypes.friendDrinkLogged &&
                notification.senderUserId == addressee.id,
          ),
          isTrue,
        );
        expect(
          (await repository.loadNotifications(addressee.id)).any(
            (notification) =>
                notification.type == AppNotificationTypes.friendDrinkLogged &&
                notification.senderUserId == requester.id,
          ),
          isTrue,
        );

        await repository.removeFriend(
          userId: requester.id,
          friendUserId: addressee.id,
        );

        final requesterNotifications = await repository.loadNotifications(
          requester.id,
        );
        final addresseeNotifications = await repository.loadNotifications(
          addressee.id,
        );

        expect(
          requesterNotifications.any(
            (notification) =>
                notification.type == AppNotificationTypes.friendDrinkLogged,
          ),
          isFalse,
        );
        expect(
          addresseeNotifications.any(
            (notification) =>
                notification.type == AppNotificationTypes.friendDrinkLogged,
          ),
          isFalse,
        );
        expect(
          requesterNotifications.map((notification) => notification.type),
          [AppNotificationTypes.friendRequestAccepted],
        );
        expect(
          addresseeNotifications.map((notification) => notification.type),
          unorderedEquals([
            AppNotificationTypes.friendRequestSent,
            AppNotificationTypes.friendRemoved,
          ]),
        );
      },
    );

    test(
      'uses profile images and app icon fallback for drink notifications',
      () async {
        final friend = await repository.signUp(
          email: 'drink-image-friend@example.com',
          password: 'secret',
          displayName: 'Drink Image Friend',
        );
        await repository.signOut();
        final loggerWithProfile = await repository.signUp(
          email: 'drink-image-logger-profile@example.com',
          password: 'secret',
          displayName: 'Drink Image Logger Profile',
          profileImagePath: '/tmp/drink-image-profile.png',
        );
        final loggerWithProfileLink = await repository.getOwnFriendProfile(
          loggerWithProfile.id,
        );
        final firstConnections = await repository.sendFriendRequestToProfile(
          userId: friend.id,
          shareCode: loggerWithProfileLink.profileShareCode!,
        );
        await repository.acceptFriendRequest(
          userId: loggerWithProfile.id,
          relationshipId: firstConnections.single.id,
        );

        final loggerWithoutProfile = await repository.signUp(
          email: 'drink-image-logger-fallback@example.com',
          password: 'secret',
          displayName: 'Drink Image Logger Fallback',
        );
        final loggerWithoutProfileLink = await repository.getOwnFriendProfile(
          loggerWithoutProfile.id,
        );
        final secondConnections = await repository.sendFriendRequestToProfile(
          userId: friend.id,
          shareCode: loggerWithoutProfileLink.profileShareCode!,
        );
        await repository.acceptFriendRequest(
          userId: loggerWithoutProfile.id,
          relationshipId: secondConnections
              .firstWhere(
                (connection) =>
                    connection.profile.id == loggerWithoutProfile.id,
              )
              .id,
        );

        final customDrink = await repository.saveCustomDrink(
          userId: loggerWithProfile.id,
          name: 'Custom Cola',
          category: DrinkCategory.nonAlcoholic,
          imagePath: '/tmp/custom-cola.png',
        );
        await repository.addDrinkEntry(
          user: loggerWithProfile,
          drink: customDrink,
        );
        final pils = (await repository.loadDefaultCatalog()).firstWhere(
          (candidate) => candidate.id == 'beer-pils',
        );
        await repository.addDrinkEntry(user: loggerWithoutProfile, drink: pils);

        final drinkNotifications =
            (await repository.loadNotifications(friend.id))
                .where(
                  (notification) =>
                      notification.type ==
                      AppNotificationTypes.friendDrinkLogged,
                )
                .toList(growable: false);

        expect(
          drinkNotifications
              .firstWhere(
                (notification) =>
                    notification.senderUserId == loggerWithProfile.id,
              )
              .imagePath,
          '/tmp/drink-image-profile.png',
        );
        expect(
          drinkNotifications
              .firstWhere(
                (notification) =>
                    notification.senderUserId == loggerWithoutProfile.id,
              )
              .imagePath,
          AppNotificationImageUrls.appIcon,
        );
      },
    );

    test(
      'shows imported friend entries in feed without notifications',
      () async {
        final friend = await repository.signUp(
          email: 'import-feed-friend@example.com',
          password: 'secret',
          displayName: 'Import Feed Friend',
        );
        await repository.signOut();
        final importer = await repository.signUp(
          email: 'import-feed-logger@example.com',
          password: 'secret',
          displayName: 'Import Feed Logger',
        );
        final importerProfile = await repository.getOwnFriendProfile(
          importer.id,
        );
        final friendConnections = await repository.sendFriendRequestToProfile(
          userId: friend.id,
          shareCode: importerProfile.profileShareCode!,
        );
        await repository.acceptFriendRequest(
          userId: importer.id,
          relationshipId: friendConnections.single.id,
        );

        final drink = (await repository.loadDefaultCatalog()).firstWhere(
          (candidate) => candidate.id == 'beer-pils',
        );
        final importedEntry = await repository.addDrinkEntry(
          user: importer,
          drink: drink,
          importSource: 'beer_with_me',
          importSourceId: 'import-1',
        );

        final feed = await repository.loadFeedDrinkPosts(userId: friend.id);
        final notifications = await repository.loadNotifications(friend.id);

        expect(
          feed.posts.map((post) => post.entry.id),
          contains(importedEntry.id),
        );
        expect(
          notifications.where(
            (notification) =>
                notification.type == AppNotificationTypes.friendDrinkLogged,
          ),
          isEmpty,
        );
      },
    );

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
      expect(await repository.loadNotifications(addressee.id), hasLength(1));

      final withdrawn = await repository.cancelFriendRequest(
        userId: requester.id,
        relationshipId: requesterConnections.single.id,
      );

      expect(withdrawn, isEmpty);
      expect(await repository.loadFriendConnections(addressee.id), isEmpty);
      expect(await repository.loadNotifications(addressee.id), isEmpty);
    });

    test('prunes old read and unread notifications', () async {
      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now();
      const userId = 'retention-user';
      final notifications = <AppNotification>[
        AppNotification(
          id: 'old-read',
          recipientUserId: userId,
          senderUserId: 'sender',
          senderDisplayName: 'Sender',
          type: AppNotificationTypes.friendRequestAccepted,
          createdAt: now.subtract(const Duration(days: 60)),
          readAt: now.subtract(const Duration(days: 31)),
        ),
        AppNotification(
          id: 'recent-read',
          recipientUserId: userId,
          senderUserId: 'sender',
          senderDisplayName: 'Sender',
          type: AppNotificationTypes.friendRequestAccepted,
          createdAt: now.subtract(const Duration(days: 60)),
          readAt: now.subtract(const Duration(days: 29)),
        ),
        AppNotification(
          id: 'old-unread',
          recipientUserId: userId,
          senderUserId: 'sender',
          senderDisplayName: 'Sender',
          type: AppNotificationTypes.friendRequestSent,
          createdAt: now.subtract(const Duration(days: 91)),
        ),
        AppNotification(
          id: 'recent-unread',
          recipientUserId: userId,
          senderUserId: 'sender',
          senderDisplayName: 'Sender',
          type: AppNotificationTypes.friendRequestSent,
          createdAt: now.subtract(const Duration(days: 89)),
        ),
      ];
      await preferences.setString(
        'glasstrail.notifications',
        jsonEncode(
          notifications
              .map((notification) => notification.toJson())
              .toList(growable: false),
        ),
      );

      final visible = await repository.loadNotifications(userId);
      final stored = List<Map<String, dynamic>>.from(
        (jsonDecode(preferences.getString('glasstrail.notifications')!) as List)
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

      expect(
        visible.map((notification) => notification.id),
        unorderedEquals(<String>['recent-read', 'recent-unread']),
      );
      expect(
        stored.map((notification) => notification['id']),
        unorderedEquals(<String>['recent-read', 'recent-unread']),
      );
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
      'persists alcohol-free custom beer and snapshots logged entries',
      () async {
        final user = await repository.signUp(
          email: 'free-beer@example.com',
          password: 'secret',
          displayName: 'Free Beer User',
        );

        final customBeer = await repository.saveCustomDrink(
          userId: user.id,
          name: 'Free Pils',
          category: DrinkCategory.beer,
          volumeMl: 500,
          isAlcoholFree: true,
        );
        await repository.addDrinkEntry(
          user: user,
          drink: customBeer,
          volumeMl: customBeer.volumeMl,
        );

        final restoredDrinks = await repository.loadCustomDrinks(user.id);
        final restoredEntries = await repository.loadEntries(user.id);

        expect(restoredDrinks.single.isAlcoholFree, isTrue);
        expect(restoredEntries.single.isAlcoholFree, isTrue);
        expect(restoredEntries.single.shouldShowAlcoholFreeMarker, isTrue);
      },
    );

    test(
      'marks custom non-alcoholic drinks as alcohol-free automatically',
      () async {
        final user = await repository.signUp(
          email: 'free-water@example.com',
          password: 'secret',
          displayName: 'Free Water User',
        );

        final customDrink = await repository.saveCustomDrink(
          userId: user.id,
          name: 'House Water',
          category: DrinkCategory.nonAlcoholic,
          isAlcoholFree: false,
        );

        expect(customDrink.isAlcoholFree, isTrue);
        expect(customDrink.shouldShowAlcoholFreeMarker, isFalse);
      },
    );

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
