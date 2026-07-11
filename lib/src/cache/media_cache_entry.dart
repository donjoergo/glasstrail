class MediaCacheEntry {
  const MediaCacheEntry({
    required this.cacheKey,
    required this.relativePath,
    required this.byteCount,
    required this.cachedAt,
    required this.lastAccessedAt,
    this.scopeUserId,
  });

  final String cacheKey;
  final String relativePath;
  final int byteCount;
  final DateTime cachedAt;
  // Tracked separately from cachedAt and updated on every read: eviction
  // (MediaCacheStore._planEvictions) removes least-recently-*accessed*
  // entries, not least-recently-cached, so a long-cached but still
  // frequently viewed image isn't evicted just because it's old.
  final DateTime lastAccessedAt;
  // Set for media that belongs to a specific account (e.g. profile photos,
  // drink entry photos) so it can be purged on sign-out/account switch via
  // MediaCacheStore.purgeScope without touching media shared across users
  // (e.g. default drink catalog images), which is left with scopeUserId
  // null.
  final String? scopeUserId;

  MediaCacheEntry copyWith({
    String? relativePath,
    int? byteCount,
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
    String? scopeUserId,
    bool clearScopeUserId = false,
  }) {
    return MediaCacheEntry(
      cacheKey: cacheKey,
      relativePath: relativePath ?? this.relativePath,
      byteCount: byteCount ?? this.byteCount,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      scopeUserId: clearScopeUserId ? null : scopeUserId ?? this.scopeUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cacheKey': cacheKey,
      'relativePath': relativePath,
      'byteCount': byteCount,
      'cachedAt': cachedAt.toUtc().toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toUtc().toIso8601String(),
      'scopeUserId': scopeUserId,
    };
  }

  factory MediaCacheEntry.fromJson(Map<String, dynamic> json) {
    return MediaCacheEntry(
      cacheKey: json['cacheKey'] as String,
      relativePath: json['relativePath'] as String,
      byteCount: (json['byteCount'] as num?)?.toInt() ?? 0,
      cachedAt: DateTime.parse(json['cachedAt'] as String).toLocal(),
      lastAccessedAt: DateTime.parse(
        json['lastAccessedAt'] as String,
      ).toLocal(),
      scopeUserId: json['scopeUserId'] as String?,
    );
  }
}
