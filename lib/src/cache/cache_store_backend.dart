// Conditional export: picks the real filesystem-backed implementation when
// dart:io is available (native platforms) and falls back to an in-memory
// stub on web, where there's no persistent filesystem to write cache files
// to.
export 'cache_store_backend_stub.dart'
    if (dart.library.io) 'cache_store_backend_io.dart';
