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
  final DateTime lastAccessedAt;
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
