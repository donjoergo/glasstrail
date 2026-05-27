import 'dart:async';

import '../friend_stats_profile.dart';
import '../cache/bootstrap_cache_store.dart';
import '../cache/bootstrap_snapshot.dart';
import '../cache/cache_debug_report.dart';
import '../cache/cache_manifest.dart';
import '../cache/cache_policy.dart';
import '../cache/media_cache_store.dart';
import '../models.dart';
import 'app_repository.dart';

typedef LocalAuthSessionLoader = LocalAuthSession? Function();

class LocalAuthSession {
  const LocalAuthSession({required this.id, required this.email});

  final String id;
  final String email;
}

abstract interface class CacheAwareAppRepository {
  Future<CacheDebugReport> loadCacheDebugReport();
}

class CachedAppRepository implements AppRepository, CacheAwareAppRepository {
  CachedAppRepository({
    required AppRepository delegate,
    required BootstrapCacheStore cacheStore,
    required MediaCacheStore mediaCacheStore,
    LocalAuthSessionLoader? loadLocalAuthSession,
  }) : _delegate = delegate,
       _cacheStore = cacheStore,
       _mediaCacheStore = mediaCacheStore,
       _loadLocalAuthSession = loadLocalAuthSession;

  static const _firstFeedPageLimit = 20;
  static const Set<CacheDomain> _userScopedDomains = <CacheDomain>{
    CacheDomain.customDrinks,
    CacheDomain.entries,
    CacheDomain.firstFeedPage,
    CacheDomain.settings,
    CacheDomain.friendConnections,
    CacheDomain.notifications,
  };

  final AppRepository _delegate;
  final BootstrapCacheStore _cacheStore;
  final MediaCacheStore _mediaCacheStore;
  final LocalAuthSessionLoader? _loadLocalAuthSession;
  final Map<CacheDomain, CacheRuntimeDebugState> _runtimeStates =
      <CacheDomain, CacheRuntimeDebugState>{};

  @override
  String get backendLabel => _delegate.backendLabel;

  @override
  bool get usesRemoteBackend => _delegate.usesRemoteBackend;

  @override
  Future<AppUser?> restoreSession({bool forceRefresh = false}) async {
    final localSession = _loadLocalAuthSession?.call();
    if (!forceRefresh && localSession != null) {
      final state = await _cacheStore.readState();
      final hasCachedUser =
          state.manifest.userId == localSession.id &&
          state.manifest.entryFor(CacheDomain.currentUser) != null &&
          state.snapshot.currentUser != null;
      if (hasCachedUser) {
        final cachedUser = state.snapshot.currentUser!;
        _recordRuntime(
          CacheDomain.currentUser,
          source:
              CachePolicy.isFresh(
                CacheDomain.currentUser,
                state.manifest.entryFor(CacheDomain.currentUser)?.updatedAt,
              )
              ? CacheReadSource.freshCache
              : CacheReadSource.staleCache,
          result:
              CachePolicy.isFresh(
                CacheDomain.currentUser,
                state.manifest.entryFor(CacheDomain.currentUser)?.updatedAt,
              )
              ? CacheRefreshResult.skippedFreshCache
              : CacheRefreshResult.servedStaleCache,
        );
        return AppUser(
          id: cachedUser.id,
          email: localSession.email,
          password: cachedUser.password,
          displayName: cachedUser.displayName,
          profileImagePath: cachedUser.profileImagePath,
          birthday: cachedUser.birthday,
          profileShareCode: cachedUser.profileShareCode,
        );
      }
    }

    try {
      final user = await _delegate.restoreSession(forceRefresh: true);
      if (user == null) {
        _recordRuntime(
          CacheDomain.currentUser,
          source: CacheReadSource.remote,
          result: CacheRefreshResult.refreshed,
        );
        return null;
      }
      await _updateCache(
        (state) => _writeCurrentUser(state, user),
        userScopeId: user.id,
      );
      _recordRuntime(
        CacheDomain.currentUser,
        source: CacheReadSource.remote,
        result: CacheRefreshResult.refreshed,
      );
      return user;
    } catch (_) {
      final state = await _cacheStore.readState();
      final cachedUser = state.snapshot.currentUser;
      final hasCachedUser =
          !forceRefresh &&
          localSession != null &&
          state.manifest.userId == localSession.id &&
          state.manifest.entryFor(CacheDomain.currentUser) != null &&
          cachedUser != null;
      if (hasCachedUser) {
        _recordRuntime(
          CacheDomain.currentUser,
          source: CacheReadSource.staleCache,
          result: CacheRefreshResult.servedStaleAfterError,
        );
        return AppUser(
          id: cachedUser.id,
          email: localSession.email,
          password: cachedUser.password,
          displayName: cachedUser.displayName,
          profileImagePath: cachedUser.profileImagePath,
          birthday: cachedUser.birthday,
          profileShareCode: cachedUser.profileShareCode,
        );
      }
      _recordRuntime(
        CacheDomain.currentUser,
        source: CacheReadSource.unknown,
        result: CacheRefreshResult.refreshFailed,
      );
      rethrow;
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) async {
    final user = await _delegate.signUp(
      email: email,
      password: password,
      displayName: displayName,
      birthday: birthday,
      profileImagePath: profileImagePath,
    );
    await _updateCache(
      (state) => _writeCurrentUser(state, user),
      userScopeId: user.id,
    );
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _delegate.signIn(email: email, password: password);
    await _updateCache(
      (state) => _writeCurrentUser(state, user),
      userScopeId: user.id,
    );
    return user;
  }

  @override
  Future<void> signOut() async {
    final state = await _cacheStore.readState();
    final userId =
        state.snapshot.currentUser?.id ?? _loadLocalAuthSession?.call()?.id;
    await _delegate.signOut();
    await _cacheStore.purgeUserScope(userId: userId);
    if (userId != null) {
      await _mediaCacheStore.purgeScope(userId);
    }
  }

  @override
  Future<void> changePassword({
    required AppUser user,
    required String currentPassword,
    required String newPassword,
  }) {
    return _delegate.changePassword(
      user: user,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAccount(AppUser user) async {
    await _delegate.deleteAccount(user);
    await _cacheStore.purgeUserScope(userId: user.id);
    await _mediaCacheStore.purgeScope(user.id);
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final updatedUser = await _delegate.updateProfile(user);
    await _updateCache(
      (state) => _writeCurrentUser(state, updatedUser),
      userScopeId: updatedUser.id,
    );
    return updatedUser;
  }

  @override
  Future<List<FriendConnection>> loadFriendConnections(
    String userId, {
    bool forceRefresh = false,
  }) {
    return _loadDomainFromCache<List<FriendConnection>>(
      domain: CacheDomain.friendConnections,
      forceRefresh: forceRefresh,
      userScopeId: userId,
      readSnapshot: (snapshot) => snapshot.friendConnections,
      remoteLoad: () =>
          _delegate.loadFriendConnections(userId, forceRefresh: true),
      writeState: (state, value) =>
          _writeFriendConnections(state, userId, value),
    );
  }

  @override
  Future<FriendProfile> getOwnFriendProfile(String userId) {
    return _delegate.getOwnFriendProfile(userId);
  }

  @override
  Future<FriendStatsProfile> loadFriendStatsProfile({
    required String userId,
    required String friendUserId,
  }) {
    return _delegate.loadFriendStatsProfile(
      userId: userId,
      friendUserId: friendUserId,
    );
  }

  @override
  Future<PublicFriendProfile> resolvePublicFriendProfileLink(String shareCode) {
    return _delegate.resolvePublicFriendProfileLink(shareCode);
  }

  @override
  Future<FriendProfile> resolveFriendProfileLink(String shareCode) {
    return _delegate.resolveFriendProfileLink(shareCode);
  }

  @override
  Future<List<FriendConnection>> sendFriendRequestToProfile({
    required String userId,
    required String shareCode,
  }) async {
    final connections = await _delegate.sendFriendRequestToProfile(
      userId: userId,
      shareCode: shareCode,
    );
    await _updateCache(
      (state) => _writeFriendConnections(state, userId, connections),
      userScopeId: userId,
    );
    return connections;
  }

  @override
  Future<List<FriendConnection>> acceptFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    final connections = await _delegate.acceptFriendRequest(
      userId: userId,
      relationshipId: relationshipId,
    );
    await _updateCache(
      (state) => _writeFriendConnections(state, userId, connections),
      userScopeId: userId,
    );
    return connections;
  }

  @override
  Future<List<FriendConnection>> rejectFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    final connections = await _delegate.rejectFriendRequest(
      userId: userId,
      relationshipId: relationshipId,
    );
    await _updateCache(
      (state) => _writeFriendConnections(state, userId, connections),
      userScopeId: userId,
    );
    return connections;
  }

  @override
  Future<List<FriendConnection>> cancelFriendRequest({
    required String userId,
    required String relationshipId,
  }) async {
    final connections = await _delegate.cancelFriendRequest(
      userId: userId,
      relationshipId: relationshipId,
    );
    await _updateCache(
      (state) => _writeFriendConnections(state, userId, connections),
      userScopeId: userId,
    );
    return connections;
  }

  @override
  Future<List<FriendConnection>> removeFriend({
    required String userId,
    required String friendUserId,
  }) async {
    final connections = await _delegate.removeFriend(
      userId: userId,
      friendUserId: friendUserId,
    );
    await _updateCache(
      (state) => _writeFriendConnections(state, userId, connections),
      userScopeId: userId,
    );
    return connections;
  }

  @override
  Future<List<AppNotification>> loadNotifications(
    String userId, {
    bool forceRefresh = false,
  }) {
    return _loadDomainFromCache<List<AppNotification>>(
      domain: CacheDomain.notifications,
      forceRefresh: forceRefresh,
      userScopeId: userId,
      readSnapshot: (snapshot) => snapshot.notifications,
      remoteLoad: () => _delegate.loadNotifications(userId, forceRefresh: true),
      writeState: (state, value) => _writeNotifications(state, userId, value),
    );
  }

  @override
  Future<List<AppNotification>> markNotificationsRead({
    required String userId,
    required List<String> notificationIds,
  }) async {
    final notifications = await _delegate.markNotificationsRead(
      userId: userId,
      notificationIds: notificationIds,
    );
    await _updateCache(
      (state) => _writeNotifications(state, userId, notifications),
      userScopeId: userId,
    );
    return notifications;
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _delegate.watchNotifications(userId).asyncMap((notifications) async {
      await _updateCache(
        (state) => _writeNotifications(state, userId, notifications),
        userScopeId: userId,
      );
      return notifications;
    });
  }

  @override
  Future<void> registerNotificationDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _delegate.registerNotificationDeviceToken(
      userId: userId,
      token: token,
      platform: platform,
    );
  }

  @override
  Future<void> unregisterNotificationDeviceToken({
    required String userId,
    required String token,
  }) {
    return _delegate.unregisterNotificationDeviceToken(
      userId: userId,
      token: token,
    );
  }

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog({
    bool forceRefresh = false,
  }) {
    return _loadDomainFromCache<List<DrinkDefinition>>(
      domain: CacheDomain.defaultCatalog,
      forceRefresh: forceRefresh,
      readSnapshot: (snapshot) => snapshot.defaultCatalog,
      remoteLoad: () => _delegate.loadDefaultCatalog(forceRefresh: true),
      writeState: (state, value) => _writeDefaultCatalog(state, value),
    );
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(
    String userId, {
    bool forceRefresh = false,
  }) {
    return _loadDomainFromCache<List<DrinkDefinition>>(
      domain: CacheDomain.customDrinks,
      forceRefresh: forceRefresh,
      userScopeId: userId,
      readSnapshot: (snapshot) => snapshot.customDrinks,
      remoteLoad: () => _delegate.loadCustomDrinks(userId, forceRefresh: true),
      writeState: (state, value) => _writeCustomDrinks(state, userId, value),
    );
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    bool isAlcoholFree = false,
    String? accentColorHex,
    String? imagePath,
  }) async {
    final drink = await _delegate.saveCustomDrink(
      userId: userId,
      drinkId: drinkId,
      name: name,
      category: category,
      volumeMl: volumeMl,
      isAlcoholFree: isAlcoholFree,
      accentColorHex: accentColorHex,
      imagePath: imagePath,
    );
    await _updateCache((state) {
      final drinks =
          <DrinkDefinition>[
            drink,
            ...state.snapshot.customDrinks.where(
              (candidate) => candidate.id != drink.id,
            ),
          ]..sort(
            (left, right) =>
                left.name.toLowerCase().compareTo(right.name.toLowerCase()),
          );
      return _writeCustomDrinks(state, userId, drinks);
    }, userScopeId: userId);
    return drink;
  }

  @override
  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  }) async {
    await _delegate.deleteCustomDrink(userId: userId, drink: drink);
    await _updateCache((state) {
      final drinks = state.snapshot.customDrinks
          .where((candidate) => candidate.id != drink.id)
          .toList(growable: false);
      return _writeCustomDrinks(state, userId, drinks);
    }, userScopeId: userId);
  }

  @override
  Future<List<DrinkEntry>> loadEntries(
    String userId, {
    bool forceRefresh = false,
  }) {
    return _loadDomainFromCache<List<DrinkEntry>>(
      domain: CacheDomain.entries,
      forceRefresh: forceRefresh,
      userScopeId: userId,
      readSnapshot: (snapshot) => snapshot.entries,
      remoteLoad: () => _delegate.loadEntries(userId, forceRefresh: true),
      writeState: (state, value) => _writeEntries(state, userId, value),
    );
  }

  @override
  Future<FeedDrinkPostPage> loadFeedDrinkPosts({
    required String userId,
    FeedDrinkPostCursor? cursor,
    int limit = 20,
    bool forceRefresh = false,
  }) {
    if (cursor != null || limit != _firstFeedPageLimit) {
      return _delegate.loadFeedDrinkPosts(
        userId: userId,
        cursor: cursor,
        limit: limit,
        forceRefresh: true,
      );
    }
    return _loadDomainFromCache<FeedDrinkPostPage>(
      domain: CacheDomain.firstFeedPage,
      forceRefresh: forceRefresh,
      userScopeId: userId,
      readSnapshot: (snapshot) =>
          snapshot.firstFeedPage ??
          const FeedDrinkPostPage(
            posts: <FeedDrinkPost>[],
            cursor: null,
            hasMore: false,
          ),
      remoteLoad: () => _delegate.loadFeedDrinkPosts(
        userId: userId,
        limit: limit,
        forceRefresh: true,
      ),
      writeState: (state, value) => _writeFirstFeedPage(state, userId, value),
    );
  }

  @override
  Future<FeedEntryCheersUpdate> setFeedEntryCheers({
    required String userId,
    required String entryId,
    required bool shouldCheer,
  }) async {
    final update = await _delegate.setFeedEntryCheers(
      userId: userId,
      entryId: entryId,
      shouldCheer: shouldCheer,
    );
    await _updateCache((state) {
      final page = state.snapshot.firstFeedPage;
      if (page == null) {
        return state;
      }
      final nextPosts = page.posts
          .map((post) {
            if (post.entry.id != entryId) {
              return post;
            }
            return post.copyWith(
              cheersCount: update.cheersCount,
              hasCurrentUserCheered: update.hasCurrentUserCheered,
            );
          })
          .toList(growable: false);
      return _writeFirstFeedPage(
        state,
        userId,
        FeedDrinkPostPage(
          posts: nextPosts,
          cursor: page.cursor,
          hasMore: page.hasMore,
        ),
      );
    }, userScopeId: userId);
    return update;
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
  }) async {
    final entry = await _delegate.addDrinkEntry(
      user: user,
      drink: drink,
      volumeMl: volumeMl,
      comment: comment,
      imagePath: imagePath,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      locationAddress: locationAddress,
      consumedAt: consumedAt,
      importSource: importSource,
      importSourceId: importSourceId,
    );
    await _updateCache((state) {
      final entries = <DrinkEntry>[
        entry,
        ...state.snapshot.entries.where(
          (candidate) => candidate.id != entry.id,
        ),
      ]..sort(_compareEntriesDescending);
      var nextState = _writeEntries(state, user.id, entries);
      final profile = FriendProfile.fromUser(user);
      final page = _upsertFeedPost(
        nextState.snapshot.firstFeedPage,
        FeedDrinkPost(entry: entry, authorProfile: profile, isOwnEntry: true),
      );
      nextState = _writeFirstFeedPage(nextState, user.id, page);
      return nextState;
    }, userScopeId: user.id);
    return entry;
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    DrinkDefinition? replacementDrink,
    double? volumeMl,
    String? comment,
    String? imagePath,
  }) async {
    final updatedEntry = await _delegate.updateDrinkEntry(
      user: user,
      entry: entry,
      replacementDrink: replacementDrink,
      volumeMl: volumeMl,
      comment: comment,
      imagePath: imagePath,
    );
    await _updateCache((state) {
      final entries =
          state.snapshot.entries
              .map(
                (candidate) =>
                    candidate.id == updatedEntry.id ? updatedEntry : candidate,
              )
              .toList(growable: false)
            ..sort(_compareEntriesDescending);
      var nextState = _writeEntries(state, user.id, entries);
      final page = state.snapshot.firstFeedPage;
      if (page != null) {
        final nextPosts = page.posts
            .map((post) {
              if (post.entry.id != updatedEntry.id) {
                return post;
              }
              return post.copyWith(entry: updatedEntry);
            })
            .toList(growable: false);
        nextState = _writeFirstFeedPage(
          nextState,
          user.id,
          FeedDrinkPostPage(
            posts: nextPosts,
            cursor: page.cursor,
            hasMore: page.hasMore,
          ),
        );
      }
      return nextState;
    }, userScopeId: user.id);
    return updatedEntry;
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) async {
    await _delegate.deleteDrinkEntry(userId: userId, entry: entry);
    await _updateCache((state) {
      final entries = state.snapshot.entries
          .where((candidate) => candidate.id != entry.id)
          .toList(growable: false);
      var nextState = _writeEntries(state, userId, entries);
      final page = state.snapshot.firstFeedPage;
      if (page != null) {
        final nextPosts = page.posts
            .where((post) => post.entry.id != entry.id)
            .toList(growable: false);
        nextState = _writeFirstFeedPage(
          nextState,
          userId,
          FeedDrinkPostPage(
            posts: nextPosts,
            cursor: nextPosts.isEmpty ? null : page.cursor,
            hasMore: page.hasMore,
          ),
        );
      }
      return nextState;
    }, userScopeId: userId);
  }

  @override
  Future<UserSettings> loadSettings(
    String userId, {
    bool forceRefresh = false,
  }) {
    return _loadDomainFromCache<UserSettings>(
      domain: CacheDomain.settings,
      forceRefresh: forceRefresh,
      userScopeId: userId,
      readSnapshot: (snapshot) => snapshot.settings ?? UserSettings.defaults(),
      remoteLoad: () => _delegate.loadSettings(userId, forceRefresh: true),
      writeState: (state, value) => _writeSettings(state, userId, value),
    );
  }

  @override
  Future<UserSettings> saveSettings(
    String userId,
    UserSettings settings,
  ) async {
    final savedSettings = await _delegate.saveSettings(userId, settings);
    await _updateCache(
      (state) => _writeSettings(state, userId, savedSettings),
      userScopeId: userId,
    );
    return savedSettings;
  }

  @override
  Future<CacheDebugReport> loadCacheDebugReport() async {
    final state = await _cacheStore.readState();
    return CacheDebugReport.fromManifest(
      manifest: state.manifest,
      runtimeStates: _runtimeStates,
      media: await _mediaCacheStore.loadDebugState(),
    );
  }

  Future<T> _loadDomainFromCache<T>({
    required CacheDomain domain,
    required bool forceRefresh,
    required T Function(BootstrapSnapshot snapshot) readSnapshot,
    required Future<T> Function() remoteLoad,
    required BootstrapCacheState Function(BootstrapCacheState state, T value)
    writeState,
    String? userScopeId,
  }) async {
    final state = await _cacheStore.readState();
    final manifestEntry = state.manifest.entryFor(domain);
    final hasUsableCache =
        manifestEntry != null &&
        (userScopeId == null || state.manifest.userId == userScopeId);
    if (!forceRefresh && hasUsableCache) {
      final isFresh = CachePolicy.isFresh(domain, manifestEntry.updatedAt);
      _recordRuntime(
        domain,
        source: isFresh
            ? CacheReadSource.freshCache
            : CacheReadSource.staleCache,
        result: isFresh
            ? CacheRefreshResult.skippedFreshCache
            : CacheRefreshResult.servedStaleCache,
      );
      return readSnapshot(state.snapshot);
    }

    try {
      final value = await remoteLoad();
      await _updateCache(
        (current) => writeState(current, value),
        userScopeId: userScopeId,
      );
      _recordRuntime(
        domain,
        source: CacheReadSource.remote,
        result: CacheRefreshResult.refreshed,
      );
      return value;
    } catch (_) {
      if (!forceRefresh && hasUsableCache) {
        _recordRuntime(
          domain,
          source: CacheReadSource.staleCache,
          result: CacheRefreshResult.servedStaleAfterError,
        );
        return readSnapshot(state.snapshot);
      }
      _recordRuntime(
        domain,
        source: CacheReadSource.unknown,
        result: CacheRefreshResult.refreshFailed,
      );
      rethrow;
    }
  }

  void _recordRuntime(
    CacheDomain domain, {
    required CacheReadSource source,
    required CacheRefreshResult result,
  }) {
    _runtimeStates[domain] = CacheRuntimeDebugState(
      lastReadSource: source,
      lastRefreshResult: result,
      lastRefreshAt: DateTime.now(),
    );
  }

  BootstrapCacheState _writeCurrentUser(
    BootstrapCacheState state,
    AppUser user,
  ) {
    final nextState =
        state.manifest.userId != null && state.manifest.userId != user.id
        ? _clearUserScopedDomains(state)
        : state;
    return nextState.copyWith(
      snapshot: nextState.snapshot.copyWith(currentUser: user),
      manifest: nextState.manifest.copyWithDomain(
        CacheDomain.currentUser,
        _manifestEntry(itemCount: 1),
        userId: user.id,
      ),
    );
  }

  BootstrapCacheState _clearUserScopedDomains(BootstrapCacheState state) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(
        customDrinks: const <DrinkDefinition>[],
        entries: const <DrinkEntry>[],
        clearFirstFeedPage: true,
        clearSettings: true,
        friendConnections: const <FriendConnection>[],
        notifications: const <AppNotification>[],
      ),
      manifest: state.manifest.removeDomains(_userScopedDomains),
    );
  }

  bool _isLocalSessionActive(String userId) {
    final loadLocalAuthSession = _loadLocalAuthSession;
    if (loadLocalAuthSession == null) {
      return true;
    }
    return loadLocalAuthSession.call()?.id == userId;
  }

  Future<void> _updateCache(
    BootstrapCacheState Function(BootstrapCacheState state) transform, {
    String? userScopeId,
  }) async {
    if (userScopeId != null && !_isLocalSessionActive(userScopeId)) {
      return;
    }
    await _cacheStore.update((state) {
      if (userScopeId != null && !_isLocalSessionActive(userScopeId)) {
        return state;
      }
      return transform(state);
    });
  }

  BootstrapCacheState _writeDefaultCatalog(
    BootstrapCacheState state,
    List<DrinkDefinition> drinks,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(defaultCatalog: drinks),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.defaultCatalog,
        _manifestEntry(itemCount: drinks.length),
      ),
    );
  }

  BootstrapCacheState _writeCustomDrinks(
    BootstrapCacheState state,
    String userId,
    List<DrinkDefinition> drinks,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(customDrinks: drinks),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.customDrinks,
        _manifestEntry(itemCount: drinks.length),
        userId: userId,
      ),
    );
  }

  BootstrapCacheState _writeEntries(
    BootstrapCacheState state,
    String userId,
    List<DrinkEntry> entries,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(entries: entries),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.entries,
        _manifestEntry(itemCount: entries.length),
        userId: userId,
      ),
    );
  }

  BootstrapCacheState _writeFirstFeedPage(
    BootstrapCacheState state,
    String userId,
    FeedDrinkPostPage page,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(firstFeedPage: page),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.firstFeedPage,
        _manifestEntry(itemCount: page.posts.length),
        userId: userId,
      ),
    );
  }

  BootstrapCacheState _writeSettings(
    BootstrapCacheState state,
    String userId,
    UserSettings settings,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(settings: settings),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.settings,
        _manifestEntry(itemCount: 1),
        userId: userId,
      ),
    );
  }

  BootstrapCacheState _writeFriendConnections(
    BootstrapCacheState state,
    String userId,
    List<FriendConnection> connections,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(friendConnections: connections),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.friendConnections,
        _manifestEntry(itemCount: connections.length),
        userId: userId,
      ),
    );
  }

  BootstrapCacheState _writeNotifications(
    BootstrapCacheState state,
    String userId,
    List<AppNotification> notifications,
  ) {
    return state.copyWith(
      snapshot: state.snapshot.copyWith(notifications: notifications),
      manifest: state.manifest.copyWithDomain(
        CacheDomain.notifications,
        _manifestEntry(itemCount: notifications.length),
        userId: userId,
      ),
    );
  }

  CacheManifestEntry _manifestEntry({required int itemCount}) {
    return CacheManifestEntry(updatedAt: DateTime.now(), itemCount: itemCount);
  }

  FeedDrinkPostPage _upsertFeedPost(
    FeedDrinkPostPage? page,
    FeedDrinkPost post,
  ) {
    final currentPage =
        page ??
        const FeedDrinkPostPage(
          posts: <FeedDrinkPost>[],
          cursor: null,
          hasMore: false,
        );
    final posts =
        <FeedDrinkPost>[
          post,
          ...currentPage.posts.where(
            (candidate) => candidate.entry.id != post.entry.id,
          ),
        ]..sort(
          (left, right) => _compareEntriesDescending(left.entry, right.entry),
        );
    final trimmedPosts = posts
        .take(_firstFeedPageLimit)
        .toList(growable: false);
    return FeedDrinkPostPage(
      posts: trimmedPosts,
      cursor: currentPage.cursor,
      hasMore: currentPage.hasMore || posts.length > _firstFeedPageLimit,
    );
  }

  int _compareEntriesDescending(DrinkEntry left, DrinkEntry right) {
    final timeComparison = right.consumedAt.compareTo(left.consumedAt);
    if (timeComparison != 0) {
      return timeComparison;
    }
    return right.id.compareTo(left.id);
  }
}
