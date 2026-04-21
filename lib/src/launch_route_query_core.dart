const _launchRouteQueryParameter = 'route';

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
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    fragment: uri.fragment.isEmpty ? null : uri.fragment,
  );
}
