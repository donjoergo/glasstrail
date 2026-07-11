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
  // Uses the enum's name (not .index) as the persisted key so reordering or
  // inserting new CacheDomain values doesn't silently remap old cached
  // entries to the wrong domain.
  String get storageKey => name;

  // Returns null (rather than throwing) for a name no longer present in
  // CacheDomain — lets old cached manifests from a previous app version
  // that had a domain since removed be read without crashing; the caller
  // just drops the unrecognized entry.
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

  // Windows are tuned per domain by how often the data actually changes and
  // how stale it's safe to look: the default drink catalog is effectively
  // static content (days), account/settings/friends change occasionally
  // (10 min/1 hr), while entries/feed reflect near-live social activity
  // (2 min). Notifications return null (never "fresh") because they're
  // read via a live stream/best-effort refresh rather than a TTL-based
  // cache — see isHotResumeDomain.
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

  // Determines which domains get revalidated when the app resumes from the
  // background (see AppController.revalidateHotDomainsOnResume): domains
  // that can go stale while the app is backgrounded and matter for what the
  // user sees right away. currentUser/defaultCatalog are excluded because
  // they rarely change during a session and aren't worth a network round
  // trip on every resume.
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
