import 'package:flutter/foundation.dart';

// Selected on web (where dart:io/Platform aren't available); MapLibre's web
// implementation is supported there, so this simply reports kIsWeb rather
// than false — the name "stub" refers to being the dart:io-free fallback,
// not to being a no-op.
bool get isMapLibrePlatformSupported => kIsWeb;
