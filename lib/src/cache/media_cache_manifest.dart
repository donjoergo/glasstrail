import 'media_cache_entry.dart';

const int mediaCacheSchemaVersion = 1;
// 128 MB: large enough to hold a meaningful working set of feed/profile
// images for offline-ish browsing, small enough not to become a significant
// chunk of a user's device storage without them realizing an app is doing
// it.
const int defaultMediaCacheSizeLimitBytes = 128 * 1024 * 1024;

class MediaCacheManifest {
  const MediaCacheManifest({
    required this.schemaVersion,
    required this.sizeLimitBytes,
    required this.entries,
    this.evictionCount = 0,
  });

  factory MediaCacheManifest.empty({
    int sizeLimitBytes = defaultMediaCacheSizeLimitBytes,
  }) {
    return MediaCacheManifest(
      schemaVersion: mediaCacheSchemaVersion,
      sizeLimitBytes: sizeLimitBytes,
      entries: const <String, MediaCacheEntry>{},
    );
  }

  final int schemaVersion;
  final int sizeLimitBytes;
  final Map<String, MediaCacheEntry> entries;
  // Cumulative count of entries ever evicted for exceeding sizeLimitBytes;
  // surfaced in CacheDebugReport as a signal that the cache is thrashing
  // (limit too small for the working set) rather than a value used by any
  // eviction logic itself.
  final int evictionCount;

  int get totalBytes =>
      entries.values.fold<int>(0, (sum, entry) => sum + entry.byteCount);

  MediaCacheManifest copyWith({
    int? schemaVersion,
    int? sizeLimitBytes,
    Map<String, MediaCacheEntry>? entries,
    int? evictionCount,
  }) {
    return MediaCacheManifest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sizeLimitBytes: sizeLimitBytes ?? this.sizeLimitBytes,
      entries: entries ?? this.entries,
      evictionCount: evictionCount ?? this.evictionCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'sizeLimitBytes': sizeLimitBytes,
      'evictionCount': evictionCount,
      'entries': <String, dynamic>{
        for (final entry in entries.entries) entry.key: entry.value.toJson(),
      },
    };
  }

  factory MediaCacheManifest.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final entries = <String, MediaCacheEntry>{};
    if (rawEntries is Map) {
      for (final entry in rawEntries.entries) {
        if (entry.value is! Map) {
          continue;
        }
        entries[entry.key.toString()] = MediaCacheEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return MediaCacheManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      sizeLimitBytes:
          (json['sizeLimitBytes'] as num?)?.toInt() ??
          defaultMediaCacheSizeLimitBytes,
      evictionCount: (json['evictionCount'] as num?)?.toInt() ?? 0,
      entries: entries,
    );
  }
}
