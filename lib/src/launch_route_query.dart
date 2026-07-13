// withoutLaunchRouteQuery is plain Uri math and works everywhere, so it's
// exported directly from core with no platform switch. clearLaunchRouteQuery
// needs the browser History API (package:web), which only exists on web —
// see browser_theme_color.dart for the general conditional-import pattern.
export 'launch_route_query_core.dart' show withoutLaunchRouteQuery;
export 'launch_route_query_stub.dart'
    if (dart.library.js_interop) 'launch_route_query_web.dart'
    show clearLaunchRouteQuery;
