// `?route=...` is used to deep-link the web app to a specific in-app route
// on first load (e.g. from a share link or PWA shortcut). Once the app has
// consumed it during startup routing, it needs to be stripped from the
// visible URL so a page refresh/bookmark doesn't keep re-navigating there —
// see clearLaunchRouteQuery (launch_route_query_web.dart) for where this is
// applied to the actual browser URL.
const _launchRouteQueryParameter = 'route';

// Pure URI transform (no browser API calls) so it can be unit tested
// without a web environment, and reused by both the web implementation and
// tests.
Uri withoutLaunchRouteQuery(Uri uri) {
  final queryParameters = Map<String, List<String>>.from(
    uri.queryParametersAll,
  );
  if (!queryParameters.containsKey(_launchRouteQueryParameter)) {
    return uri;
  }
  queryParameters.remove(_launchRouteQueryParameter);
  if (queryParameters.isNotEmpty) {
    return uri.replace(queryParameters: queryParameters);
  }
  // Uri.replace(queryParameters: {}) would still leave a trailing "?" in
  // the resulting URL, so once every query parameter is gone the URI is
  // rebuilt from scratch without a query component at all.
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    fragment: uri.fragment.isEmpty ? null : uri.fragment,
  );
}
