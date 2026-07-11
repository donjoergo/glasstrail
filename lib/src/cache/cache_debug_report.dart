import 'cache_manifest.dart';
import 'cache_policy.dart';

// These read/refresh outcomes are purely diagnostic (surfaced in a
// debug/settings screen and used by AppController to decide which domains
// need revalidating) — not part of the cache's actual read/write logic —
// so engineers and support can tell whether a screen's data came from a
// live fetch or an aging cache without reproducing the issue live.
enum CacheReadSource { unknown, remote, freshCache, staleCache }

enum CacheRefreshResult {
  unknown,
  refreshed,
  skippedFreshCache,
  servedStaleCache,
  servedStaleAfterError,
  refreshFailed,
}

class CacheDomainDebugState {
  const CacheDomainDebugState({
    required this.domain,
    required this.hasData,
    required this.isFresh,
    this.updatedAt,
    this.itemCount,
    this.lastReadSource = CacheReadSource.unknown,
    this.lastRefreshResult = CacheRefreshResult.unknown,
    this.lastRefreshAt,
  });

  final CacheDomain domain;
  final bool hasData;
  final bool isFresh;
  final DateTime? updatedAt;
  final int? itemCount;
  final CacheReadSource lastReadSource;
  final CacheRefreshResult lastRefreshResult;
  final DateTime? lastRefreshAt;

  Duration? age({DateTime? now}) {
    final updatedAt = this.updatedAt;
    if (updatedAt == null) {
      return null;
    }
    return (now ?? DateTime.now()).difference(updatedAt);
  }
}

class MediaCacheDebugState {
  const MediaCacheDebugState({
    required this.totalBytes,
    required this.itemCount,
    required this.evictionCount,
    required this.sizeLimitBytes,
  });

  final int totalBytes;
  final int itemCount;
  final int evictionCount;
  final int sizeLimitBytes;
}

class CacheDebugReport {
  const CacheDebugReport({
    required this.schemaVersion,
    required this.userId,
    required this.domains,
    required this.media,
  });

  factory CacheDebugReport.fromManifest({
    required CacheManifest manifest,
    required Map<CacheDomain, CacheRuntimeDebugState> runtimeStates,
    required MediaCacheDebugState media,
    DateTime? now,
  }) {
    return CacheDebugReport(
      schemaVersion: manifest.schemaVersion,
      userId: manifest.userId,
      domains: <CacheDomain, CacheDomainDebugState>{
        for (final domain in CacheDomain.values)
          domain: _debugStateForDomain(
            domain,
            manifest.entryFor(domain),
            runtimeStates[domain],
            now: now,
          ),
      },
      media: media,
    );
  }

  final int schemaVersion;
  final String? userId;
  final Map<CacheDomain, CacheDomainDebugState> domains;
  final MediaCacheDebugState media;

  CacheDomainDebugState? domain(CacheDomain domain) => domains[domain];
}

class CacheRuntimeDebugState {
  const CacheRuntimeDebugState({
    this.lastReadSource = CacheReadSource.unknown,
    this.lastRefreshResult = CacheRefreshResult.unknown,
    this.lastRefreshAt,
  });

  final CacheReadSource lastReadSource;
  final CacheRefreshResult lastRefreshResult;
  final DateTime? lastRefreshAt;
}

CacheDomainDebugState _debugStateForDomain(
  CacheDomain domain,
  CacheManifestEntry? entry,
  CacheRuntimeDebugState? runtimeState, {
  DateTime? now,
}) {
  final updatedAt = entry?.updatedAt;
  return CacheDomainDebugState(
    domain: domain,
    hasData: entry != null,
    isFresh: CachePolicy.isFresh(domain, updatedAt, now: now),
    updatedAt: updatedAt,
    itemCount: entry?.itemCount,
    lastReadSource: runtimeState?.lastReadSource ?? CacheReadSource.unknown,
    lastRefreshResult:
        runtimeState?.lastRefreshResult ?? CacheRefreshResult.unknown,
    lastRefreshAt: runtimeState?.lastRefreshAt,
  );
}
