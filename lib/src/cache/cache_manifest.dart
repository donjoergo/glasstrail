import 'cache_policy.dart';

// Bump whenever the on-disk shape of BootstrapSnapshot/CacheManifest changes
// in a way older cached JSON can't be deserialized into: BootstrapCacheStore
// compares this against the persisted value and wipes the cache rather than
// risk crashing on (or silently misreading) an incompatible payload.
const int cacheSchemaVersion = 1;

class CacheManifestEntry {
  const CacheManifestEntry({required this.updatedAt, this.itemCount});

  final DateTime updatedAt;
  final int? itemCount;

  CacheManifestEntry copyWith({DateTime? updatedAt, int? itemCount}) {
    return CacheManifestEntry(
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  // Persisted as UTC (so the stored value is unambiguous regardless of the
  // device's timezone at write time) but converted back to local on read,
  // matching CachePolicy.isFresh's use of local DateTime.now() for
  // freshness comparisons.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'itemCount': itemCount,
    };
  }

  factory CacheManifestEntry.fromJson(Map<String, dynamic> json) {
    return CacheManifestEntry(
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      itemCount: (json['itemCount'] as num?)?.toInt(),
    );
  }
}

class CacheManifest {
  const CacheManifest({
    required this.schemaVersion,
    required this.domains,
    this.userId,
  });

  factory CacheManifest.empty() {
    return const CacheManifest(
      schemaVersion: cacheSchemaVersion,
      domains: <CacheDomain, CacheManifestEntry>{},
    );
  }

  final int schemaVersion;
  // Records which account the cached (user-scoped) domains belong to, so
  // callers can detect a mismatch (cache from a different account than the
  // one now signed in) and purge before trusting any of it — see
  // BootstrapCacheStore.purgeUserScope.
  final String? userId;
  final Map<CacheDomain, CacheManifestEntry> domains;

  CacheManifest copyWith({
    int? schemaVersion,
    String? userId,
    bool clearUserId = false,
    Map<CacheDomain, CacheManifestEntry>? domains,
  }) {
    return CacheManifest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      userId: clearUserId ? null : userId ?? this.userId,
      domains: domains ?? this.domains,
    );
  }

  CacheManifest copyWithDomain(
    CacheDomain domain,
    CacheManifestEntry entry, {
    String? userId,
  }) {
    return copyWith(
      userId: userId,
      domains: <CacheDomain, CacheManifestEntry>{...domains, domain: entry},
    );
  }

  CacheManifest removeDomains(Iterable<CacheDomain> domainsToRemove) {
    final nextDomains = Map<CacheDomain, CacheManifestEntry>.from(domains);
    for (final domain in domainsToRemove) {
      nextDomains.remove(domain);
    }
    return copyWith(domains: nextDomains);
  }

  CacheManifestEntry? entryFor(CacheDomain domain) => domains[domain];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'userId': userId,
      'domains': <String, dynamic>{
        for (final entry in domains.entries)
          entry.key.storageKey: entry.value.toJson(),
      },
    };
  }

  factory CacheManifest.fromJson(Map<String, dynamic> json) {
    final rawDomains = json['domains'];
    final domains = <CacheDomain, CacheManifestEntry>{};
    if (rawDomains is Map) {
      for (final entry in rawDomains.entries) {
        final domain = CacheDomainX.maybeFromStorage(entry.key.toString());
        if (domain == null || entry.value is! Map) {
          continue;
        }
        domains[domain] = CacheManifestEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return CacheManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String?,
      domains: domains,
    );
  }
}
