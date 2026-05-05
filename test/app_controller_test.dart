import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/beer_with_me_import.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/push_notification_service.dart';
import 'package:glasstrail/src/repository/app_repository.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/stats_calculator.dart';

import 'support/test_harness.dart';

AppLocalizations _l10n(String languageCode) =>
    lookupAppLocalizations(Locale(languageCode));

void main() {
  test('bootstraps independent repository reads in parallel', () async {
    final repository = _BootstrapProbeRepository();

    final bootstrapFuture = AppController.bootstrapWithRepository(repository);

    expect(repository.loadDefaultCatalogCalls, 1);
    expect(repository.restoreSessionCalls, 1);
    expect(repository.loadCustomDrinksCalls, 0);
    expect(repository.loadEntriesCalls, 0);
    expect(repository.loadFeedDrinkPostsCalls, 0);
    expect(repository.loadSettingsCalls, 0);
    expect(repository.loadFriendConnectionsCalls, 0);
    expect(repository.loadNotificationsCalls, 0);

    repository.defaultCatalogCompleter.complete(buildDefaultDrinkCatalog());
    repository.restoreSessionCompleter.complete(
      const AppUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User Example',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(repository.loadCustomDrinksCalls, 1);
    expect(repository.loadEntriesCalls, 1);
    expect(repository.loadFeedDrinkPostsCalls, 1);
    expect(repository.loadSettingsCalls, 1);
    expect(repository.loadFriendConnectionsCalls, 1);
    expect(repository.loadNotificationsCalls, 1);

    repository.customDrinksCompleter.complete(const <DrinkDefinition>[]);
    repository.entriesCompleter.complete(const <DrinkEntry>[]);
    repository.feedPostsCompleter.complete(
      const FeedDrinkPostPage(
        posts: <FeedDrinkPost>[],
        cursor: null,
        hasMore: false,
      ),
    );
    repository.settingsCompleter.complete(UserSettings.defaults());
    repository.friendConnectionsCompleter.complete(const <FriendConnection>[]);
    repository.notificationsCompleter.complete(const <AppNotification>[]);

    final controller = await bootstrapFuture;
    expect(controller.isAuthenticated, isTrue);
    expect(controller.availableDrinks, isNotEmpty);
    expect(controller.notifications, isEmpty);
  });

  test('refreshes app data through the repository again', () async {
    final repository = _BootstrapProbeRepository();
    repository.defaultCatalogCompleter.complete(buildDefaultDrinkCatalog());
    repository.restoreSessionCompleter.complete(
      const AppUser(
        id: 'refresh-user',
        email: 'refresh@example.com',
        displayName: 'Refresh Example',
      ),
    );
    repository.customDrinksCompleter.complete(const <DrinkDefinition>[]);
    repository.entriesCompleter.complete(const <DrinkEntry>[]);
    repository.feedPostsCompleter.complete(
      const FeedDrinkPostPage(
        posts: <FeedDrinkPost>[],
        cursor: null,
        hasMore: false,
      ),
    );
    repository.settingsCompleter.complete(UserSettings.defaults());
    repository.friendConnectionsCompleter.complete(const <FriendConnection>[]);
    repository.notificationsCompleter.complete(const <AppNotification>[]);

    final controller = await AppController.bootstrapWithRepository(repository);

    final success = await controller.refreshData();

    expect(success, isTrue);
    expect(repository.loadDefaultCatalogCalls, 2);
    expect(repository.loadCustomDrinksCalls, 2);
    expect(repository.loadEntriesCalls, 2);
    expect(repository.loadFeedDrinkPostsCalls, 2);
    expect(repository.loadSettingsCalls, 2);
    expect(repository.loadFriendConnectionsCalls, 2);
    expect(repository.loadNotificationsCalls, 2);
  });

  test('accepting a friend request refreshes feed posts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = LocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final requester = await repository.signUp(
      email: 'accept-refresh-requester@example.com',
      password: 'password123',
      displayName: 'Accept Refresh Requester',
    );
    final drink = (await repository.loadDefaultCatalog()).firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final requesterEntry = await repository.addDrinkEntry(
      user: requester,
      drink: drink,
      comment: 'Visible after accept',
    );
    await repository.signOut();
    final addressee = await repository.signUp(
      email: 'accept-refresh-addressee@example.com',
      password: 'password123',
      displayName: 'Accept Refresh Addressee',
    );
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );

    final controller = await AppController.bootstrapWithRepository(repository);

    expect(
      controller.feedPosts.map((post) => post.entry.id),
      isNot(contains(requesterEntry.id)),
    );

    final success = await controller.acceptFriendRequest(
      controller.incomingFriendRequests.single,
    );

    expect(success, isTrue);
    expect(controller.friends, hasLength(1));
    expect(
      controller.feedPosts.map((post) => post.entry.id),
      contains(requesterEntry.id),
    );
  });

  test('removing a friend drops their feed posts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = LocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final friend = await repository.signUp(
      email: 'remove-refresh-friend@example.com',
      password: 'password123',
      displayName: 'Remove Refresh Friend',
    );
    final drink = (await repository.loadDefaultCatalog()).firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final friendEntry = await repository.addDrinkEntry(
      user: friend,
      drink: drink,
      comment: 'Should disappear after remove',
    );
    final friendProfile = await repository.getOwnFriendProfile(friend.id);
    await repository.signOut();
    final user = await repository.signUp(
      email: 'remove-refresh-user@example.com',
      password: 'password123',
      displayName: 'Remove Refresh User',
    );
    final connections = await repository.sendFriendRequestToProfile(
      userId: user.id,
      shareCode: friendProfile.profileShareCode!,
    );
    await repository.acceptFriendRequest(
      userId: friend.id,
      relationshipId: connections.single.id,
    );

    final controller = await AppController.bootstrapWithRepository(repository);

    expect(
      controller.feedPosts.map((post) => post.entry.id),
      contains(friendEntry.id),
    );

    final success = await controller.removeFriend(controller.friends.single);

    expect(success, isTrue);
    expect(controller.friends, isEmpty);
    expect(
      controller.feedPosts.map((post) => post.entry.id),
      isNot(contains(friendEntry.id)),
    );
  });

  test(
    'refreshing an accepted friend notification reloads friends and feed',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = LocalAppRepository(
        await SharedPreferences.getInstance(),
      );
      final addressee = await repository.signUp(
        email: 'accepted-notification-addressee@example.com',
        password: 'password123',
        displayName: 'Accepted Notification Addressee',
      );
      final drink = (await repository.loadDefaultCatalog()).firstWhere(
        (candidate) => candidate.id == 'beer-pils',
      );
      final addresseeEntry = await repository.addDrinkEntry(
        user: addressee,
        drink: drink,
        comment: 'Visible after notification refresh',
      );
      final addresseeProfile = await repository.getOwnFriendProfile(
        addressee.id,
      );
      await repository.signOut();
      final requester = await repository.signUp(
        email: 'accepted-notification-requester@example.com',
        password: 'password123',
        displayName: 'Accepted Notification Requester',
      );
      final connections = await repository.sendFriendRequestToProfile(
        userId: requester.id,
        shareCode: addresseeProfile.profileShareCode!,
      );

      final controller = await AppController.bootstrapWithRepository(
        repository,
      );

      expect(
        controller.feedPosts.map((post) => post.entry.id),
        isNot(contains(addresseeEntry.id)),
      );

      await repository.acceptFriendRequest(
        userId: addressee.id,
        relationshipId: connections.single.id,
      );
      final notification = (await repository.loadNotifications(requester.id))
          .firstWhere(
            (candidate) =>
                candidate.type == AppNotificationTypes.friendRequestAccepted,
          );

      final success = await controller.refreshForNotification(notification);

      expect(success, isTrue);
      expect(controller.friends, hasLength(1));
      expect(
        controller.feedPosts.map((post) => post.entry.id),
        contains(addresseeEntry.id),
      );
    },
  );

  test('refreshing a removed friend notification drops feed posts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = LocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final friend = await repository.signUp(
      email: 'removed-notification-friend@example.com',
      password: 'password123',
      displayName: 'Removed Notification Friend',
    );
    final drink = (await repository.loadDefaultCatalog()).firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final friendEntry = await repository.addDrinkEntry(
      user: friend,
      drink: drink,
      comment: 'Removed after notification refresh',
    );
    final friendProfile = await repository.getOwnFriendProfile(friend.id);
    await repository.signOut();
    final user = await repository.signUp(
      email: 'removed-notification-user@example.com',
      password: 'password123',
      displayName: 'Removed Notification User',
    );
    final connections = await repository.sendFriendRequestToProfile(
      userId: user.id,
      shareCode: friendProfile.profileShareCode!,
    );
    await repository.acceptFriendRequest(
      userId: friend.id,
      relationshipId: connections.single.id,
    );

    final controller = await AppController.bootstrapWithRepository(repository);

    expect(
      controller.feedPosts.map((post) => post.entry.id),
      contains(friendEntry.id),
    );

    await repository.removeFriend(userId: friend.id, friendUserId: user.id);
    final notification = (await repository.loadNotifications(user.id))
        .firstWhere(
          (candidate) => candidate.type == AppNotificationTypes.friendRemoved,
        );

    final success = await controller.refreshForNotification(notification);

    expect(success, isTrue);
    expect(controller.friends, isEmpty);
    expect(
      controller.feedPosts.map((post) => post.entry.id),
      isNot(contains(friendEntry.id)),
    );
  });

  test('optimistically toggles cheers with per-entry pending state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = _BlockingCheersLocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final logger = await repository.signUp(
      email: 'controller-cheers-logger@example.com',
      password: 'password123',
      displayName: 'Controller Cheers Logger',
    );
    final loggerProfile = await repository.getOwnFriendProfile(logger.id);
    await repository.signOut();
    final cheerer = await repository.signUp(
      email: 'controller-cheers-cheerer@example.com',
      password: 'password123',
      displayName: 'Controller Cheers Cheerer',
    );
    final connections = await repository.sendFriendRequestToProfile(
      userId: cheerer.id,
      shareCode: loggerProfile.profileShareCode!,
    );
    await repository.acceptFriendRequest(
      userId: logger.id,
      relationshipId: connections.single.id,
    );
    final drink = (await repository.loadDefaultCatalog()).firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final entry = await repository.addDrinkEntry(user: logger, drink: drink);

    final controller = await AppController.bootstrapWithRepository(repository);
    final post = controller.feedPosts.firstWhere(
      (candidate) => candidate.entry.id == entry.id,
    );

    final toggleFuture = controller.toggleFeedEntryCheers(post);
    await repository.setCheersStarted.future;
    await Future<void>.delayed(Duration.zero);

    expect(controller.isFeedEntryCheersPending(entry.id), isTrue);
    final optimisticPost = controller.feedPosts.firstWhere(
      (candidate) => candidate.entry.id == entry.id,
    );
    expect(optimisticPost.cheersCount, 1);
    expect(optimisticPost.hasCurrentUserCheered, isTrue);

    repository.unblockSetCheers();
    final success = await toggleFuture;

    expect(success, isTrue);
    expect(controller.isFeedEntryCheersPending(entry.id), isFalse);
    final confirmedPost = controller.feedPosts.firstWhere(
      (candidate) => candidate.entry.id == entry.id,
    );
    expect(confirmedPost.cheersCount, 1);
    expect(confirmedPost.hasCurrentUserCheered, isTrue);
  });

  test('rolls back optimistic cheers when the repository call fails', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = _BlockingCheersLocalAppRepository(
      await SharedPreferences.getInstance(),
    )..failSetCheers = true;
    final logger = await repository.signUp(
      email: 'controller-cheers-fail-logger@example.com',
      password: 'password123',
      displayName: 'Controller Cheers Fail Logger',
    );
    final loggerProfile = await repository.getOwnFriendProfile(logger.id);
    await repository.signOut();
    final cheerer = await repository.signUp(
      email: 'controller-cheers-fail-cheerer@example.com',
      password: 'password123',
      displayName: 'Controller Cheers Fail Cheerer',
    );
    final connections = await repository.sendFriendRequestToProfile(
      userId: cheerer.id,
      shareCode: loggerProfile.profileShareCode!,
    );
    await repository.acceptFriendRequest(
      userId: logger.id,
      relationshipId: connections.single.id,
    );
    final drink = (await repository.loadDefaultCatalog()).firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final entry = await repository.addDrinkEntry(user: logger, drink: drink);

    final controller = await AppController.bootstrapWithRepository(repository);
    final post = controller.feedPosts.firstWhere(
      (candidate) => candidate.entry.id == entry.id,
    );

    final toggleFuture = controller.toggleFeedEntryCheers(post);
    await repository.setCheersStarted.future;
    await Future<void>.delayed(Duration.zero);

    expect(controller.isFeedEntryCheersPending(entry.id), isTrue);

    repository.unblockSetCheers();
    final success = await toggleFuture;

    expect(success, isFalse);
    expect(controller.isFeedEntryCheersPending(entry.id), isFalse);
    final rolledBackPost = controller.feedPosts.firstWhere(
      (candidate) => candidate.entry.id == entry.id,
    );
    expect(rolledBackPost.cheersCount, 0);
    expect(rolledBackPost.hasCurrentUserCheered, isFalse);
    expect(
      controller.takeFlashMessage(_l10n('en')),
      _l10n('en').somethingWentWrong,
    );
  });

  test('refreshing a cheers notification reloads feed cheers state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = LocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final owner = await repository.signUp(
      email: 'controller-cheers-owner@example.com',
      password: 'password123',
      displayName: 'Controller Cheers Owner',
    );
    final drink = (await repository.loadDefaultCatalog()).firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final entry = await repository.addDrinkEntry(user: owner, drink: drink);
    final ownerProfile = await repository.getOwnFriendProfile(owner.id);
    await repository.signOut();
    final friend = await repository.signUp(
      email: 'controller-cheers-owner-friend@example.com',
      password: 'password123',
      displayName: 'Controller Cheers Owner Friend',
    );
    final connections = await repository.sendFriendRequestToProfile(
      userId: friend.id,
      shareCode: ownerProfile.profileShareCode!,
    );
    await repository.acceptFriendRequest(
      userId: owner.id,
      relationshipId: connections.single.id,
    );
    await repository.signOut();
    await repository.signIn(
      email: 'controller-cheers-owner@example.com',
      password: 'password123',
    );

    final controller = await AppController.bootstrapWithRepository(repository);
    expect(
      controller.feedPosts
          .firstWhere((post) => post.entry.id == entry.id)
          .cheersCount,
      0,
    );

    await repository.setFeedEntryCheers(
      userId: friend.id,
      entryId: entry.id,
      shouldCheer: true,
    );
    await Future<void>.delayed(Duration.zero);

    final notification = controller.notifications.firstWhere(
      (candidate) => candidate.type == AppNotificationTypes.friendDrinkCheered,
    );
    final success = await controller.refreshForNotification(notification);

    expect(success, isTrue);
    final refreshedPost = controller.feedPosts.firstWhere(
      (post) => post.entry.id == entry.id,
    );
    expect(refreshedPost.cheersCount, 1);
    expect(refreshedPost.hasCurrentUserCheered, isFalse);
  });

  test('tracks sign-up as the active busy action while pending', () async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.signUp,
    );
    final controller = await AppController.bootstrapWithRepository(repository);

    final signUpFuture = controller.signUp(
      email: 'busy-signup@example.com',
      password: 'password123',
      displayName: 'Busy Signup',
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.isBusy, isTrue);
    expect(controller.busyAction, AppBusyAction.signUp);
    expect(controller.isBusyFor(AppBusyAction.signUp), isTrue);

    repository.unblock();
    await signUpFuture;

    expect(controller.isBusy, isFalse);
    expect(controller.busyAction, isNull);
  });

  test('tracks settings updates separately from other busy actions', () async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.updateSettings,
    );
    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'busy-settings@example.com',
      password: 'password123',
      displayName: 'Busy Settings',
    );

    final updateFuture = controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.isBusy, isTrue);
    expect(controller.busyAction, AppBusyAction.updateSettings);
    expect(controller.isBusyFor(AppBusyAction.updateSettings), isTrue);
    expect(controller.isBusyFor(AppBusyAction.signOut), isFalse);

    repository.unblock();
    await updateFuture;

    expect(controller.isBusy, isFalse);
    expect(controller.busyAction, isNull);
  });

  test('counts unread notifications and marks them read', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = LocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final requester = await repository.signUp(
      email: 'controller-notify-requester@example.com',
      password: 'password123',
      displayName: 'Controller Requester',
    );
    await repository.signOut();
    final addressee = await repository.signUp(
      email: 'controller-notify-addressee@example.com',
      password: 'password123',
      displayName: 'Controller Addressee',
    );
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );

    final controller = await AppController.bootstrapWithRepository(repository);

    expect(controller.notifications, hasLength(1));
    expect(controller.unreadNotificationCount, 1);

    final success = await controller.markAllNotificationsRead();

    expect(success, isTrue);
    expect(controller.unreadNotificationCount, 0);
    expect(controller.notifications.single.isRead, isTrue);
  });

  test('keeps local notification reads over stale stream snapshots', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = _ManualNotificationStreamLocalRepository(
      await SharedPreferences.getInstance(),
    );
    addTearDown(repository.dispose);
    final requester = await repository.signUp(
      email: 'stale-notify-requester@example.com',
      password: 'password123',
      displayName: 'Stale Requester',
    );
    await repository.signOut();
    final addressee = await repository.signUp(
      email: 'stale-notify-addressee@example.com',
      password: 'password123',
      displayName: 'Stale Addressee',
    );
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.sendFriendRequestToProfile(
      userId: requester.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    final staleNotification = (await repository.loadNotifications(
      addressee.id,
    )).single;
    final controller = await AppController.bootstrapWithRepository(repository);

    expect(controller.unreadNotificationCount, 1);

    final success = await controller.markNotificationsRead(<String>[
      staleNotification.id,
    ]);
    repository.emitNotifications(<AppNotification>[staleNotification]);
    await Future<void>.delayed(Duration.zero);

    expect(success, isTrue);
    expect(controller.unreadNotificationCount, 0);
    expect(controller.notifications.single.isRead, isTrue);
  });

  test('rolls back only the failed optimistic notification read', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = _ManualNotificationStreamLocalRepository(
      await SharedPreferences.getInstance(),
    );
    addTearDown(repository.dispose);
    final addressee = await repository.signUp(
      email: 'partial-read-addressee@example.com',
      password: 'password123',
      displayName: 'Partial Read Addressee',
    );
    final addresseeProfile = await repository.getOwnFriendProfile(addressee.id);
    await repository.signOut();
    final requesterOne = await repository.signUp(
      email: 'partial-read-requester-one@example.com',
      password: 'password123',
      displayName: 'Partial Read One',
    );
    await repository.sendFriendRequestToProfile(
      userId: requesterOne.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    await repository.signOut();
    final requesterTwo = await repository.signUp(
      email: 'partial-read-requester-two@example.com',
      password: 'password123',
      displayName: 'Partial Read Two',
    );
    await repository.sendFriendRequestToProfile(
      userId: requesterTwo.id,
      shareCode: addresseeProfile.profileShareCode!,
    );
    await repository.signOut();
    await repository.signIn(
      email: 'partial-read-addressee@example.com',
      password: 'password123',
    );
    final controller = await AppController.bootstrapWithRepository(repository);
    final firstNotification = controller.notifications.first;
    final secondNotification = controller.notifications.last;

    expect(
      await controller.markNotificationsRead(<String>[firstNotification.id]),
      isTrue,
    );

    repository.failNextMark = true;
    final success = await controller.markNotificationsRead(<String>[
      secondNotification.id,
    ]);

    expect(success, isFalse);
    expect(
      controller.notifications
          .firstWhere((notification) => notification.id == firstNotification.id)
          .isRead,
      isTrue,
    );
    expect(
      controller.notifications
          .firstWhere(
            (notification) => notification.id == secondNotification.id,
          )
          .isUnread,
      isTrue,
    );
    expect(controller.unreadNotificationCount, 1);
  });

  test(
    'keeps authentication successful when token registration fails',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = _FailingTokenLocalAppRepository(
        await SharedPreferences.getInstance(),
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
        pushNotificationService: const _StaticPushNotificationService(
          PushDeviceToken(token: 'fcm-token', platform: 'android'),
        ),
      );

      final success = await controller.signUp(
        email: 'push-best-effort@example.com',
        password: 'password123',
        displayName: 'Push Best Effort',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(repository.registerCalls, 1);
    },
  );

  test('unregisters push token when sign-out wins registration race', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = _DelayedTokenLocalAppRepository(
      await SharedPreferences.getInstance(),
    );
    final controller = await AppController.bootstrapWithRepository(
      repository,
      pushNotificationService: const _StaticPushNotificationService(
        PushDeviceToken(token: 'race-token', platform: 'android'),
      ),
    );

    final signUpFuture = controller.signUp(
      email: 'push-race@example.com',
      password: 'password123',
      displayName: 'Push Race',
    );
    await repository.registerStarted.future;

    final signOutSuccess = await controller.signOut();
    expect(signOutSuccess, isTrue);
    expect(controller.isAuthenticated, isFalse);

    repository.completeRegistration();
    expect(await signUpFuture, isTrue);

    expect(repository.registeredTokens, hasLength(1));
    expect(repository.unregisteredTokens, hasLength(1));
    expect(
      repository.unregisteredTokens.single.userId,
      repository.registeredTokens.single.userId,
    );
    expect(repository.unregisteredTokens.single.token, 'race-token');
    expect(controller.isAuthenticated, isFalse);
  });

  test(
    'retries push token unregister after a transient sign-out failure',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = _FailingOnceTokenCleanupLocalAppRepository(
        await SharedPreferences.getInstance(),
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
        pushNotificationService: const _StaticPushNotificationService(
          PushDeviceToken(token: 'retry-token', platform: 'android'),
        ),
      );

      expect(
        await controller.signUp(
          email: 'push-retry@example.com',
          password: 'password123',
          displayName: 'Push Retry',
        ),
        isTrue,
      );

      expect(await controller.signOut(), isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(repository.unregisterCalls, 1);

      repository.failUnregister = false;
      expect(await controller.signOut(), isTrue);
      expect(repository.unregisterCalls, 2);
      expect(repository.unregisteredTokens.single.token, 'retry-token');
    },
  );

  test(
    'awaits push token subscription cancellation before unregistering',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final tokenRefreshes = _ControlledPushTokenRefreshStream();
      final repository = _OrderingTokenCleanupLocalAppRepository(
        await SharedPreferences.getInstance(),
        isCancellationComplete: () => tokenRefreshes.cancelCompleted,
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
        pushNotificationService: _ControlledPushNotificationService(
          token: const PushDeviceToken(
            token: 'ordered-token',
            platform: 'android',
          ),
          refreshStream: tokenRefreshes,
        ),
      );

      expect(
        await controller.signUp(
          email: 'push-order@example.com',
          password: 'password123',
          displayName: 'Push Order',
        ),
        isTrue,
      );

      final signOutFuture = controller.signOut();
      await tokenRefreshes.cancelStarted.future;
      expect(repository.unregisterSawPendingCancellation, isFalse);

      tokenRefreshes.completeCancel();
      expect(await signOutFuture, isTrue);
      expect(repository.unregisterSawPendingCancellation, isFalse);
      expect(repository.unregisterCalls, 1);
    },
  );

  test('localizes success flash messages and drink names', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

    await controller.signUp(
      email: 'flash@example.com',
      password: 'password123',
      displayName: 'Flash Beispiel',
    );
    expect(controller.takeFlashMessage(german), 'Willkommen bei Glass Trail.');

    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    final redWine = controller.availableDrinks.firstWhere(
      (drink) => drink.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: redWine, volumeMl: redWine.volumeMl);

    expect(controller.takeFlashMessage(german), 'Rotwein erfasst.');
  });

  test(
    'imports BeerWithMe exports with duplicates, errors, and no_address',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');
      await controller.signUp(
        email: 'import@example.com',
        password: 'password123',
        displayName: 'Import Beispiel',
      );
      await controller.updateSettings(
        controller.settings.copyWith(localeCode: 'de'),
      );

      final exportFile = parseBeerWithMeExportFile('''
      [
        {
          "id": 172120176,
          "timestamp": "2022-06-06T22:55:15.000+02:00",
          "glassType": "WineRose",
          "address": "no_address"
        },
        {
          "id": 172120177,
          "timestamp": "2022-06-06T23:10:00.000+02:00",
          "glassType": "Beer",
          "longitude": 10.8827774,
          "latitude": 49.5635995,
          "address": "Am Buck 19\\nHerzogenaurach\\nDeutschland"
        },
        {
          "id": 172120178,
          "timestamp": "2022-06-06T23:20:00.000+02:00",
          "glassType": "UnknownType"
        }
      ]
    ''');

      final firstImport = await controller.importBeerWithMeExport(exportFile);

      expect(firstImport.totalRows, 3);
      expect(firstImport.importedCount, 2);
      expect(firstImport.skippedDuplicateCount, 0);
      expect(firstImport.errorCount, 1);
      expect(
        firstImport.errors.single.message,
        german.beerWithMeImportUnknownGlassType('UnknownType'),
      );

      final rose = controller.entries.firstWhere(
        (entry) => entry.importSourceId == '172120176',
      );
      expect(rose.drinkId, 'wine-rosé-wine');
      expect(rose.volumeMl, 150);
      expect(rose.locationAddress, isNull);
      expect(rose.locationLatitude, isNull);
      expect(rose.locationLongitude, isNull);

      final beer = controller.entries.firstWhere(
        (entry) => entry.importSourceId == '172120177',
      );
      expect(beer.drinkId, 'beer-classic');
      expect(beer.volumeMl, 500);
      expect(beer.locationAddress, 'Am Buck 19, Herzogenaurach, Deutschland');
      expect(beer.locationLatitude, 49.5635995);
      expect(beer.locationLongitude, 10.8827774);
      expect(beer.importSource, beerWithMeImportSource);

      final secondImport = await controller.importBeerWithMeExport(exportFile);

      expect(secondImport.totalRows, 3);
      expect(secondImport.importedCount, 0);
      expect(secondImport.skippedDuplicateCount, 2);
      expect(secondImport.errorCount, 1);
    },
  );

  test(
    'publishes BeerWithMe import progress while the import is pending',
    () async {
      final repository = await buildBlockingLocalRepository(
        blockedAction: AppBusyAction.addDrinkEntry,
      );
      final controller = await AppController.bootstrapWithRepository(
        repository,
      );
      await controller.signUp(
        email: 'import-progress@example.com',
        password: 'password123',
        displayName: 'Import Progress Example',
      );

      final exportFile = parseBeerWithMeExportFile('''
      [
        {
          "id": 172120179,
          "timestamp": "2022-06-06T22:55:15.000+02:00",
          "glassType": "WineRose",
          "address": "no_address"
        }
      ]
    ''');

      final importFuture = controller.importBeerWithMeExport(exportFile);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isBusyFor(AppBusyAction.importBeerWithMe), isTrue);
      expect(
        controller.beerWithMeImportProgress,
        const TypeMatcher<BeerWithMeImportProgress>(),
      );
      expect(controller.beerWithMeImportProgress?.totalCount, 1);
      expect(controller.beerWithMeImportProgress?.processedCount, 0);
      expect(controller.beerWithMeImportProgress?.importedCount, 0);
      expect(controller.beerWithMeImportProgress?.errorCount, 0);

      repository.unblock();
      final result = await importFuture;

      expect(result.importedCount, 1);
      expect(controller.beerWithMeImportProgress, isNull);
      expect(controller.isBusy, isFalse);
    },
  );

  test('cancels BeerWithMe import after the current row finishes', () async {
    final repository = await buildBlockingLocalRepository(
      blockedAction: AppBusyAction.addDrinkEntry,
    );
    final controller = await AppController.bootstrapWithRepository(repository);
    await controller.signUp(
      email: 'import-cancel@example.com',
      password: 'password123',
      displayName: 'Import Cancel Example',
    );

    final exportFile = parseBeerWithMeExportFile('''
      [
        {
          "id": 172120180,
          "timestamp": "2022-06-06T22:55:15.000+02:00",
          "glassType": "WineRose",
          "address": "no_address"
        },
        {
          "id": 172120181,
          "timestamp": "2022-06-06T23:10:00.000+02:00",
          "glassType": "Beer",
          "address": "no_address"
        }
      ]
    ''');

    final importFuture = controller.importBeerWithMeExport(exportFile);
    await Future<void>.delayed(Duration.zero);

    expect(controller.requestBeerWithMeImportCancellation(), isTrue);
    expect(controller.isBeerWithMeImportCancellationRequested, isTrue);

    repository.unblock();
    final result = await importFuture;

    expect(result.wasCancelled, isTrue);
    expect(result.totalRows, 2);
    expect(result.processedCount, 1);
    expect(result.importedCount, 1);
    expect(result.skippedDuplicateCount, 0);
    expect(result.errorCount, 0);
    expect(
      controller.entries.map((entry) => entry.importSourceId),
      contains('172120180'),
    );
    expect(
      controller.entries.map((entry) => entry.importSourceId),
      isNot(contains('172120181')),
    );
    expect(controller.isBeerWithMeImportCancellationRequested, isFalse);
    expect(controller.isBusy, isFalse);
  });

  test(
    'hides global drinks from selectors while keeping history localization',
    () async {
      final controller = await buildTestController();

      await controller.signUp(
        email: 'hide-global@example.com',
        password: 'password123',
        displayName: 'Hide Global Example',
      );

      final redWine = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'wine-red-wine',
      );
      await controller.addDrinkEntry(
        drink: redWine,
        volumeMl: redWine.volumeMl,
      );

      final hidden = await controller.hideGlobalDrink(redWine.id);

      expect(hidden, isTrue);
      expect(
        controller.availableDrinks.any((drink) => drink.id == redWine.id),
        isFalse,
      );
      expect(
        controller.recentDrinks.any((drink) => drink.id == redWine.id),
        isFalse,
      );
      expect(
        controller.localizedEntryDrinkName(
          controller.entries.first,
          localeCode: 'de',
        ),
        'Rotwein',
      );
    },
  );

  test(
    'hides whole global categories from selectors while keeping history localization',
    () async {
      final controller = await buildTestController();

      await controller.signUp(
        email: 'hide-category@example.com',
        password: 'password123',
        displayName: 'Hide Category Example',
      );

      final pils = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-pils',
      );
      await controller.addDrinkEntry(drink: pils, volumeMl: pils.volumeMl);

      final hidden = await controller.hideGlobalCategory(DrinkCategory.beer);

      expect(hidden, isTrue);
      expect(controller.isGlobalCategoryHidden(DrinkCategory.beer), isTrue);
      expect(controller.settings.hiddenGlobalDrinkCategories, <DrinkCategory>[
        DrinkCategory.beer,
      ]);
      expect(
        controller.availableDrinks.any(
          (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
        ),
        isFalse,
      );
      expect(
        controller.recentDrinks.any(
          (drink) => drink.category == DrinkCategory.beer,
        ),
        isFalse,
      );
      expect(
        controller.localizedEntryDrinkName(
          controller.entries.first,
          localeCode: 'de',
        ),
        'Pils',
      );

      final shown = await controller.showGlobalCategory(DrinkCategory.beer);

      expect(shown, isTrue);
      expect(controller.isGlobalCategoryHidden(DrinkCategory.beer), isFalse);
      expect(
        controller.availableDrinks.any((drink) => drink.id == pils.id),
        isTrue,
      );
    },
  );

  test('reorders visible global drinks inside a category', () async {
    final controller = await buildTestController();

    await controller.signUp(
      email: 'reorder-global@example.com',
      password: 'password123',
      displayName: 'Reorder Global Example',
    );

    final initialBeerIds = controller.availableDrinks
        .where(
          (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
        )
        .map((drink) => drink.id)
        .toList(growable: false);
    final reorderedIds = <String>[
      initialBeerIds[1],
      initialBeerIds[0],
      ...initialBeerIds.skip(2),
    ];

    final success = await controller.reorderGlobalDrinks(
      category: DrinkCategory.beer,
      orderedDrinkIds: reorderedIds,
    );

    expect(success, isTrue);
    final updatedBeerIds = controller.availableDrinks
        .where(
          (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
        )
        .map((drink) => drink.id)
        .toList(growable: false);
    expect(updatedBeerIds, reorderedIds);
  });

  test(
    'reorders custom drinks together with global drinks inside a category',
    () async {
      final controller = await buildTestController();

      await controller.signUp(
        email: 'reorder-custom@example.com',
        password: 'password123',
        displayName: 'Reorder Custom Example',
      );
      await controller.saveCustomDrink(
        name: 'Zulu Tonic',
        category: DrinkCategory.cocktails,
        volumeMl: 200,
      );
      final customDrink = controller.customDrinks.single;
      final mojito = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'cocktails-mojito',
      );
      final currentCocktailIds = controller.availableDrinks
          .where((drink) => drink.category == DrinkCategory.cocktails)
          .map((drink) => drink.id)
          .toList(growable: false);

      final success = await controller.reorderGlobalDrinks(
        category: DrinkCategory.cocktails,
        orderedDrinkIds: <String>[
          customDrink.id,
          mojito.id,
          ...currentCocktailIds.where(
            (id) => id != customDrink.id && id != mojito.id,
          ),
        ],
      );

      expect(success, isTrue);
      final updatedCocktailIds = controller.availableDrinks
          .where((drink) => drink.category == DrinkCategory.cocktails)
          .map((drink) => drink.id)
          .toList(growable: false);
      expect(updatedCocktailIds.first, customDrink.id);
      expect(updatedCocktailIds[1], mojito.id);
      expect(
        controller
            .settings
            .globalDrinkOrderOverrides[DrinkCategory.cocktails]
            ?.first,
        customDrink.id,
      );
    },
  );

  test(
    'removes a custom drink photo when saving an existing custom drink',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');

      await controller.signUp(
        email: 'custom-photo-remove@example.com',
        password: 'password123',
        displayName: 'Custom Photo Remove',
      );
      controller.takeFlashMessage(german);

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
        imagePath: '/tmp/custom-drink.png',
      );
      controller.takeFlashMessage(german);

      final existing = controller.customDrinks.single;

      final success = await controller.saveCustomDrink(
        drinkId: existing.id,
        name: existing.name,
        category: existing.category,
        volumeMl: existing.volumeMl,
        imagePath: null,
      );

      expect(success, isTrue);
      expect(controller.customDrinks.single.imagePath, isNull);
      expect(
        controller.takeFlashMessage(german),
        'Eigenes Getränk gespeichert.',
      );
    },
  );

  test('localizes mapped repository error messages', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

    await controller.signUp(
      email: 'duplicate@example.com',
      password: 'password123',
      displayName: 'Erstes Konto',
    );
    controller.takeFlashMessage(german);

    final success = await controller.signUp(
      email: 'duplicate@example.com',
      password: 'password123',
      displayName: 'Zweites Konto',
    );

    expect(success, isFalse);
    expect(
      controller.takeFlashMessage(german),
      'Es gibt bereits ein Konto mit dieser E-Mail-Adresse.',
    );
  });

  test(
    'removes the current user profile image when updating the profile',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');

      await controller.signUp(
        email: 'profile-image@example.com',
        password: 'password123',
        displayName: 'Profile Image Example',
        profileImagePath: '/tmp/profile-before.png',
      );
      controller.takeFlashMessage(german);

      final success = await controller.updateProfile(
        displayName: 'Profile Image Example',
        profileImagePath: null,
        clearProfileImage: true,
      );

      expect(success, isTrue);
      expect(controller.currentUser?.profileImagePath, isNull);
      expect(controller.takeFlashMessage(german), 'Profil aktualisiert.');
    },
  );

  test('updates a drink entry and emits a localized success message', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

    await controller.signUp(
      email: 'edit-entry@example.com',
      password: 'password123',
      displayName: 'Edit Entry Example',
    );
    controller.takeFlashMessage(german);

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Vorher',
      imagePath: '/tmp/initial-image.png',
    );
    controller.takeFlashMessage(german);

    final success = await controller.updateDrinkEntry(
      entry: controller.entries.single,
      comment: 'Nachher',
      imagePath: null,
    );

    expect(success, isTrue);
    expect(controller.entries.single.comment, 'Nachher');
    expect(controller.entries.single.imagePath, isNull);
    expect(controller.takeFlashMessage(german), 'Eintrag aktualisiert.');
  });

  test(
    'deletes a custom drink and emits a localized success message',
    () async {
      final controller = await buildTestController();
      final german = _l10n('de');

      await controller.signUp(
        email: 'delete-custom-drink@example.com',
        password: 'password123',
        displayName: 'Delete Custom Drink Example',
      );
      controller.takeFlashMessage(german);

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
      );
      controller.takeFlashMessage(german);

      final drink = controller.customDrinks.single;
      await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
      controller.takeFlashMessage(german);

      final success = await controller.deleteCustomDrink(drink);

      expect(success, isTrue);
      expect(controller.customDrinks, isEmpty);
      expect(controller.entries, hasLength(1));
      expect(
        controller.localizedEntryDrinkName(
          controller.entries.single,
          localeCode: 'de',
        ),
        'Office Brew',
      );
      expect(controller.takeFlashMessage(german), 'Eigenes Getränk gelöscht.');
    },
  );

  test('deletes a drink entry and emits a localized success message', () async {
    final controller = await buildTestController();
    final german = _l10n('de');

    await controller.signUp(
      email: 'delete-entry@example.com',
      password: 'password123',
      displayName: 'Delete Entry Example',
    );
    controller.takeFlashMessage(german);

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    controller.takeFlashMessage(german);

    final success = await controller.deleteDrinkEntry(
      controller.entries.single,
    );

    expect(success, isTrue);
    expect(controller.entries, isEmpty);
    expect(controller.takeFlashMessage(german), 'Eintrag gelöscht.');
  });

  test('re-evaluates streak statistics after deleting a drink entry', () async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'streak-delete@example.com',
      password: 'password123',
      displayName: 'Streak Delete Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final yesterday = today.subtract(const Duration(days: 1));

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: yesterday,
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: today,
    );

    await controller.refreshData();

    expect(controller.statistics.currentStreak, 2);
    expect(
      controller.statistics.streakMessageState,
      StreakMessageState.continuedToday,
    );

    final entryToDelete = controller.entries.firstWhere(
      (entry) =>
          entry.consumedAt.year == today.year &&
          entry.consumedAt.month == today.month &&
          entry.consumedAt.day == today.day,
    );

    final success = await controller.deleteDrinkEntry(entryToDelete);

    expect(success, isTrue);
    expect(controller.statistics.currentStreak, 0);
    expect(controller.statistics.streakThroughYesterday, 1);
    expect(
      controller.statistics.streakMessageState,
      StreakMessageState.keepAlive,
    );
  });
}

class _ManualNotificationStreamLocalRepository extends LocalAppRepository {
  _ManualNotificationStreamLocalRepository(super.preferences);

  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  bool failNextMark = false;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notificationsController.stream;
  }

  @override
  Future<List<AppNotification>> markNotificationsRead({
    required String userId,
    required List<String> notificationIds,
  }) {
    if (failNextMark) {
      failNextMark = false;
      throw const AppException('Notification read failed.');
    }
    return super.markNotificationsRead(
      userId: userId,
      notificationIds: notificationIds,
    );
  }

  void emitNotifications(List<AppNotification> notifications) {
    _notificationsController.add(notifications);
  }

  Future<void> dispose() => _notificationsController.close();
}

class _BlockingCheersLocalAppRepository extends LocalAppRepository {
  _BlockingCheersLocalAppRepository(super.preferences);

  final setCheersStarted = Completer<void>();
  final _setCheersCompleter = Completer<void>();
  bool failSetCheers = false;

  void unblockSetCheers() {
    if (!_setCheersCompleter.isCompleted) {
      _setCheersCompleter.complete();
    }
  }

  @override
  Future<FeedEntryCheersUpdate> setFeedEntryCheers({
    required String userId,
    required String entryId,
    required bool shouldCheer,
  }) async {
    if (!setCheersStarted.isCompleted) {
      setCheersStarted.complete();
    }
    await _setCheersCompleter.future;
    if (failSetCheers) {
      throw const AppException('Cheers failed.');
    }
    return super.setFeedEntryCheers(
      userId: userId,
      entryId: entryId,
      shouldCheer: shouldCheer,
    );
  }
}

class _StaticPushNotificationService extends PushNotificationService {
  const _StaticPushNotificationService(this.token);

  final PushDeviceToken token;

  @override
  Future<PushDeviceToken?> getDeviceToken() async => token;

  @override
  Stream<PushDeviceToken> get tokenRefreshes =>
      const Stream<PushDeviceToken>.empty();

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async => null;

  @override
  Stream<PushNotificationOpen> get openedNotifications =>
      const Stream<PushNotificationOpen>.empty();
}

class _ControlledPushNotificationService extends PushNotificationService {
  const _ControlledPushNotificationService({
    required this.token,
    required this.refreshStream,
  });

  final PushDeviceToken token;
  final _ControlledPushTokenRefreshStream refreshStream;

  @override
  Future<PushDeviceToken?> getDeviceToken() async => token;

  @override
  Stream<PushDeviceToken> get tokenRefreshes => refreshStream;

  @override
  Future<PushNotificationOpen?> consumeInitialOpen() async => null;

  @override
  Stream<PushNotificationOpen> get openedNotifications =>
      const Stream<PushNotificationOpen>.empty();
}

class _ControlledPushTokenRefreshStream extends Stream<PushDeviceToken> {
  final cancelStarted = Completer<void>();
  final _cancelCompleter = Completer<void>();

  bool get cancelCompleted => _cancelCompleter.isCompleted;

  void completeCancel() {
    if (!_cancelCompleter.isCompleted) {
      _cancelCompleter.complete();
    }
  }

  @override
  StreamSubscription<PushDeviceToken> listen(
    void Function(PushDeviceToken event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _ControlledPushTokenRefreshSubscription(
      onCancel: () {
        if (!cancelStarted.isCompleted) {
          cancelStarted.complete();
        }
        return _cancelCompleter.future;
      },
    );
  }
}

class _ControlledPushTokenRefreshSubscription
    implements StreamSubscription<PushDeviceToken> {
  _ControlledPushTokenRefreshSubscription({required this.onCancel});

  final Future<void> Function() onCancel;

  @override
  Future<void> cancel() => onCancel();

  @override
  void onData(void Function(PushDeviceToken data)? handleData) {}

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}

  @override
  bool get isPaused => false;

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future<E>.value(futureValue);
}

class _FailingTokenLocalAppRepository extends LocalAppRepository {
  _FailingTokenLocalAppRepository(super.preferences);

  int registerCalls = 0;

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    registerCalls++;
    throw const AppException('Token registration failed.');
  }
}

class _FailingOnceTokenCleanupLocalAppRepository extends LocalAppRepository {
  _FailingOnceTokenCleanupLocalAppRepository(super.preferences);

  bool failUnregister = true;
  int unregisterCalls = 0;
  final unregisteredTokens = <_TokenCall>[];

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) async {
    unregisterCalls++;
    if (failUnregister) {
      throw const AppException('Token cleanup failed.');
    }
    unregisteredTokens.add(_TokenCall(userId: userId, token: token));
  }
}

class _OrderingTokenCleanupLocalAppRepository extends LocalAppRepository {
  _OrderingTokenCleanupLocalAppRepository(
    super.preferences, {
    required this.isCancellationComplete,
  });

  final bool Function() isCancellationComplete;
  int unregisterCalls = 0;
  bool unregisterSawPendingCancellation = false;

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) async {
    unregisterCalls++;
    if (!isCancellationComplete()) {
      unregisterSawPendingCancellation = true;
    }
  }
}

class _DelayedTokenLocalAppRepository extends LocalAppRepository {
  _DelayedTokenLocalAppRepository(super.preferences);

  final registerStarted = Completer<void>();
  final _registrationCompleter = Completer<void>();
  final registeredTokens = <_TokenCall>[];
  final unregisteredTokens = <_TokenCall>[];

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    registeredTokens.add(
      _TokenCall(userId: userId, token: token, platform: platform),
    );
    if (!registerStarted.isCompleted) {
      registerStarted.complete();
    }
    return _registrationCompleter.future;
  }

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) async {
    unregisteredTokens.add(_TokenCall(userId: userId, token: token));
  }

  void completeRegistration() {
    if (!_registrationCompleter.isCompleted) {
      _registrationCompleter.complete();
    }
  }
}

class _TokenCall {
  const _TokenCall({required this.userId, required this.token, this.platform});

  final String userId;
  final String token;
  final String? platform;
}

class _BootstrapProbeRepository implements AppRepository {
  final defaultCatalogCompleter = Completer<List<DrinkDefinition>>();
  final restoreSessionCompleter = Completer<AppUser?>();
  final customDrinksCompleter = Completer<List<DrinkDefinition>>();
  final entriesCompleter = Completer<List<DrinkEntry>>();
  final feedPostsCompleter = Completer<FeedDrinkPostPage>();
  final settingsCompleter = Completer<UserSettings>();
  final friendConnectionsCompleter = Completer<List<FriendConnection>>();
  final notificationsCompleter = Completer<List<AppNotification>>();

  int loadDefaultCatalogCalls = 0;
  int restoreSessionCalls = 0;
  int loadCustomDrinksCalls = 0;
  int loadEntriesCalls = 0;
  int loadFeedDrinkPostsCalls = 0;
  int loadSettingsCalls = 0;
  int loadFriendConnectionsCalls = 0;
  int loadNotificationsCalls = 0;

  @override
  String get backendLabel => 'probe';

  @override
  bool get usesRemoteBackend => false;

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog() {
    loadDefaultCatalogCalls++;
    return defaultCatalogCompleter.future;
  }

  @override
  Future<AppUser?> restoreSession() {
    restoreSessionCalls++;
    return restoreSessionCompleter.future;
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(String userId) {
    loadCustomDrinksCalls++;
    return customDrinksCompleter.future;
  }

  @override
  Future<List<DrinkEntry>> loadEntries(String userId) {
    loadEntriesCalls++;
    return entriesCompleter.future;
  }

  @override
  Future<FeedDrinkPostPage> loadFeedDrinkPosts({
    required String userId,
    FeedDrinkPostCursor? cursor,
    int limit = 20,
  }) {
    loadFeedDrinkPostsCalls++;
    return feedPostsCompleter.future;
  }

  @override
  Future<UserSettings> loadSettings(String userId) {
    loadSettingsCalls++;
    return settingsCompleter.future;
  }

  @override
  Future<List<FriendConnection>> loadFriendConnections(String userId) {
    loadFriendConnectionsCalls++;
    return friendConnectionsCompleter.future;
  }

  @override
  Future<List<AppNotification>> loadNotifications(String userId) {
    loadNotificationsCalls++;
    return notificationsCompleter.future;
  }

  @override
  Future<List<AppNotification>> markNotificationsRead({
    required String userId,
    required List<String> notificationIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return const Stream<List<AppNotification>>.empty();
  }

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    DateTime? consumedAt,
    String? importSource,
    String? importSourceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FeedEntryCheersUpdate> setFeedEntryCheers({
    required String userId,
    required String entryId,
    required bool shouldCheer,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> acceptFriendRequest({
    required String userId,
    required String relationshipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FriendProfile> getOwnFriendProfile(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> rejectFriendRequest({
    required String userId,
    required String relationshipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> cancelFriendRequest({
    required String userId,
    required String relationshipId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> removeFriend({
    required String userId,
    required String friendUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FriendProfile> resolveFriendProfileLink(String shareCode) {
    throw UnimplementedError();
  }

  @override
  Future<PublicFriendProfile> resolvePublicFriendProfileLink(String shareCode) {
    throw UnimplementedError();
  }

  @override
  Future<List<FriendConnection>> sendFriendRequestToProfile({
    required String userId,
    required String shareCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    bool isAlcoholFree = false,
    String? imagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserSettings> saveSettings(String userId, UserSettings settings) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> updateProfile(AppUser user) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  }) {
    throw UnimplementedError();
  }
}
