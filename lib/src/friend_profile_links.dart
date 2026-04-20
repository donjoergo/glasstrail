import 'package:flutter/foundation.dart';

import 'app_routes.dart';

const _configuredFriendProfileBaseUrl = String.fromEnvironment(
  'FRIEND_PROFILE_BASE_URL',
  defaultValue: 'https://glasstrail.vercel.app',
);

String friendProfileLinkForCode(String shareCode) {
  return '${_friendProfileBaseUrl()}${AppRoutes.friendProfileRoute(shareCode)}';
}

String friendProfileAppLinkForCode(String shareCode) {
  return '${_friendProfileBaseUrl()}/#${AppRoutes.friendProfileRoute(shareCode)}';
}

String _friendProfileBaseUrl() {
  final configured = _configuredFriendProfileBaseUrl.trim();
  if (configured.isNotEmpty) {
    return _trimTrailingSlash(configured);
  }

  final base = Uri.base;
  if (kIsWeb && (base.scheme == 'http' || base.scheme == 'https')) {
    return _trimTrailingSlash(base.origin);
  }
  return 'https://glasstrail.vercel.app';
}

String _trimTrailingSlash(String value) {
  var result = value;
  while (result.endsWith('/')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}
