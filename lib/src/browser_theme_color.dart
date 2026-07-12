// Conditional-import barrel: package:web (and dart:js_interop) only exist
// on web builds, so browser_theme_color_web.dart can't be imported
// unconditionally without breaking native (iOS/Android/desktop) builds.
// `dart.library.js_interop` is true only on web, letting the compiler pick
// the web implementation there and the native-safe no-op stub everywhere
// else — this is the standard Dart pattern for platform-specific code
// behind a single shared API surface (see also runtime_platform.dart,
// launch_route_query.dart, maplibre_web_registration.dart for the same
// pattern with dart.library.io / dart.library.js_interop).
export 'browser_theme_color_stub.dart'
    if (dart.library.js_interop) 'browser_theme_color_web.dart'
    show BrowserThemeColorSync;
