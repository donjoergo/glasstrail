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
    // app_links is a native-platform-channel plugin; on web the browser's
    // own URL already is the deep link, so there's nothing for it to
    // report and calling it would just throw.
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

  // Links we generate ourselves (see friend_profile_links.dart) encode the
  // route both as a `?route=` query param and as a `#fragment`, since the
  // hosting page needs the query param server-side while a client-side
  // router typically reads the fragment. Query param wins first because
  // it's unambiguous; the fragment is the web SPA fallback; a bare path is
  // the native deep-link / universal-link case.
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
    // Re-derive the canonical route from the extracted share code (instead
    // of trusting `normalized` as-is) so a malformed or tampered-with
    // share code in the link can't be forwarded into app navigation.
    final shareCode = AppRoutes.friendProfileShareCode(normalized);
    return shareCode == null ? null : AppRoutes.friendProfileRoute(shareCode);
  }
  return AppRoutes.isRestorable(normalized) ? normalized : null;
}
