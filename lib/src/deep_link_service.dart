import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'app_routes.dart';

abstract class DeepLinkService {
  const DeepLinkService();

  Future<Uri?> getInitialUri();

  Stream<Uri> get uriStream;
}

class PlatformDeepLinkService extends DeepLinkService {
  const PlatformDeepLinkService();

  @override
  Future<Uri?> getInitialUri() {
    if (kIsWeb) {
      return Future<Uri?>.value();
    }
    return AppLinks().getInitialLink();
  }

  @override
  Stream<Uri> get uriStream {
    if (kIsWeb) {
      return const Stream<Uri>.empty();
    }
    return AppLinks().uriLinkStream;
  }
}

class DisabledDeepLinkService extends DeepLinkService {
  const DisabledDeepLinkService();

  @override
  Future<Uri?> getInitialUri() async => null;

  @override
  Stream<Uri> get uriStream => const Stream<Uri>.empty();
}

String? routeFromDeepLink(Uri? uri) {
  if (uri == null) {
    return null;
  }

  final queryRoute = _normalizedDeepLinkRoute(uri.queryParameters['route']);
  if (queryRoute != null) {
    return queryRoute;
  }

  final fragment = uri.fragment.trim();
  final fragmentRoute = _normalizedDeepLinkRoute(
    fragment.isEmpty || fragment.startsWith('/') ? fragment : '/$fragment',
  );
  if (fragmentRoute != null) {
    return fragmentRoute;
  }

  return _normalizedDeepLinkRoute(uri.path);
}

String? _normalizedDeepLinkRoute(String? routeName) {
  if (routeName == null || routeName.trim().isEmpty) {
    return null;
  }
  final normalized = AppRoutes.normalize(routeName.trim());
  if (AppRoutes.isFriendProfileRoute(normalized)) {
    final shareCode = AppRoutes.friendProfileShareCode(normalized);
    return shareCode == null ? null : AppRoutes.friendProfileRoute(shareCode);
  }
  return AppRoutes.isRestorable(normalized) ? normalized : null;
}
