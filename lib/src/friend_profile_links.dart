import 'package:flutter/foundation.dart';

import 'app_routes.dart';

const _productionFriendProfileBaseUrl = 'https://glasstrail.vercel.app';

String friendProfileLinkForCode(String shareCode) {
  return '${_friendProfileBaseUrl()}${AppRoutes.friendProfileRoute(shareCode)}';
}

String friendProfileAppLinkForCode(String shareCode) {
  final path = AppRoutes.friendProfileRoute(shareCode);
  return '${_friendProfileBaseUrl()}/?route=${Uri.encodeQueryComponent(path)}#$path';
}

String _friendProfileBaseUrl() {
  final base = Uri.base;
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
