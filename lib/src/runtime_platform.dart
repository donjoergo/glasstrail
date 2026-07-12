// Conditional-import barrel selecting a platform check for whether MapLibre
// is supported. dart:io (and therefore Platform.isAndroid/isIOS) doesn't
// exist on web, so the io-backed check can only be used where
// dart.library.io is available; web instead relies on kIsWeb via the stub.
// Same pattern as browser_theme_color.dart / launch_route_query.dart /
// maplibre_web_registration.dart — see browser_theme_color.dart for the
// fuller explanation of why conditional imports are needed at all.
export 'runtime_platform_stub.dart'
    if (dart.library.io) 'runtime_platform_io.dart';
