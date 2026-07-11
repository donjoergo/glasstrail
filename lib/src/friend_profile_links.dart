import 'package:flutter/foundation.dart';

import 'app_routes.dart';

const _productionFriendProfileBaseUrl = 'https://glasstrail.vercel.app';

String friendProfileLinkForCode(String shareCode) {
  return '${_friendProfileBaseUrl()}${AppRoutes.friendProfileRoute(shareCode)}';
}

String friendProfileAppLinkForCode(String shareCode) {
  // Both a `?route=` query param and a `#fragment` are encoded so the link
  // works whichever way it's opened: hosting/SSR needs the query param,
  // while deep_link_service.dart also understands the fragment as a
  // client-side-routing fallback. See routeFromDeepLink for the parsing
  // priority.
  final path = AppRoutes.friendProfileRoute(shareCode);
  return '${_friendProfileBaseUrl()}/?route=${Uri.encodeQueryComponent(path)}#$path';
}

String _friendProfileBaseUrl() {
  final base = Uri.base;
  // On web, use the app's own origin so links work in local/staging
  // deployments too, not just production. Native platforms have no
  // meaningful browser origin, so they always share the production URL —
  // that's fine since the app intercepts it as a deep link before it's
  // ever actually loaded in a browser.
  if (kIsWeb && (base.scheme == 'http' || base.scheme == 'https')) {
    return _trimTrailingSlash(base.origin);
  }
  return _productionFriendProfileBaseUrl;
}

String _trimTrailingSlash(String value) {
  var result = value;
  while (result.endsWith('/')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}
