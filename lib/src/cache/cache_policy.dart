enum CacheDomain {
  currentUser,
  defaultCatalog,
  customDrinks,
  entries,
  firstFeedPage,
  settings,
  friendConnections,
  notifications,
}

extension CacheDomainX on CacheDomain {
  String get storageKey => name;

  static CacheDomain? maybeFromStorage(String value) {
    for (final candidate in CacheDomain.values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
    return null;
  }
}

class CachePolicy {
  const CachePolicy._();

  static Duration? freshnessWindow(CacheDomain domain) {
    return switch (domain) {
      CacheDomain.currentUser => const Duration(minutes: 10),
      CacheDomain.defaultCatalog => const Duration(days: 7),
      CacheDomain.settings => const Duration(hours: 1),
      CacheDomain.customDrinks => const Duration(minutes: 10),
      CacheDomain.friendConnections => const Duration(minutes: 10),
      CacheDomain.entries => const Duration(minutes: 2),
      CacheDomain.firstFeedPage => const Duration(minutes: 2),
      CacheDomain.notifications => null,
    };
  }

  static bool isFresh(
    CacheDomain domain,
    DateTime? updatedAt, {
    DateTime? now,
  }) {
    if (updatedAt == null) {
      return false;
    }
    final window = freshnessWindow(domain);
    if (window == null) {
      return false;
    }
    final age = (now ?? DateTime.now()).difference(updatedAt);
    return age <= window;
  }

  static bool isHotResumeDomain(CacheDomain domain) {
    return switch (domain) {
      CacheDomain.settings ||
      CacheDomain.customDrinks ||
      CacheDomain.entries ||
      CacheDomain.firstFeedPage ||
      CacheDomain.friendConnections ||
      CacheDomain.notifications => true,
      CacheDomain.currentUser || CacheDomain.defaultCatalog => false,
    };
  }
}
