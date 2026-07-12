// maplibre_gl_web (and the platform-view sanitization it needs) only builds
// on web; native platforms use maplibre_gl's built-in platform channel
// implementation instead and never call ensureMapLibreWebRegistered's real
// logic. Same conditional-import pattern as browser_theme_color.dart.
export 'maplibre_web_registration_stub.dart'
    if (dart.library.js_interop) 'maplibre_web_registration_web.dart';
