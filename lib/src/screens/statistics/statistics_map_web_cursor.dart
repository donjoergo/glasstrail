// Conditional export keeps `dart:js_interop`/`package:web` (web-only APIs)
// out of the dependency graph on non-web platforms, where MapLibre is
// rendered natively and there is no DOM cursor/mouseleave to manage.
export 'statistics_map_web_cursor_stub.dart'
    if (dart.library.js_interop) 'statistics_map_web_cursor_web.dart'
    show attachStatisticsMapWebMouseLeaveListener, setStatisticsMapWebCursor;
