import 'package:shared_preferences/shared_preferences.dart';

import 'app_routes.dart';

class RouteMemory {
  RouteMemory._(this._preferences)
    : _lastRoute = _normalizeStoredRoute(
        _preferences?.getString(_lastRouteKey),
      ),
      _openFeedAfterNextAuth =
          _preferences?.getBool(_openFeedAfterNextAuthKey) ?? false;

  RouteMemory.disabled() : this._(null);

  static const _lastRouteKey = 'glasstrail.last_route';
  static const _openFeedAfterNextAuthKey =
      'glasstrail.open_feed_after_next_auth';

  final SharedPreferences? _preferences;
  String _lastRoute;
  bool _openFeedAfterNextAuth;

  String get lastRoute => _lastRoute;

  static Future<RouteMemory> create() async {
    final preferences = await SharedPreferences.getInstance();
    return RouteMemory._(preferences);
  }

  String resolveInitialRoute(String? requestedRoute) {
    final normalizedRequested = AppRoutes.normalize(requestedRoute);
    if (_openFeedAfterNextAuth &&
        AppRoutes.isExplicitPostAuthRedirectRoute(normalizedRequested)) {
      return normalizedRequested;
    }

    if (_openFeedAfterNextAuth) {
      return AppRoutes.auth;
    }

    return switch (normalizedRequested) {
      AppRoutes.root || AppRoutes.auth || AppRoutes.feed => _lastRoute,
      _ when AppRoutes.isPostAuthRoute(normalizedRequested) =>
        normalizedRequested,
      _ => _lastRoute,
    };
  }

  Future<void> rememberRoute(String routeName) async {
    if (!AppRoutes.isRestorable(routeName)) {
      return;
    }
    final normalizedRoute = AppRoutes.postAuthRoute(routeName);
    if (_lastRoute == normalizedRoute) {
      return;
    }
    _lastRoute = normalizedRoute;
    await _preferences?.setString(_lastRouteKey, normalizedRoute);
  }

  Future<void> markLoggedOut() async {
    _openFeedAfterNextAuth = true;
    _lastRoute = AppRoutes.feed;
    await _preferences?.setBool(_openFeedAfterNextAuthKey, true);
    await _preferences?.setString(_lastRouteKey, AppRoutes.feed);
  }

  Future<String> consumePostAuthRoute(String? redirectRoute) async {
    final normalizedRedirect = AppRoutes.normalize(redirectRoute);
    final hasExplicitRedirect = AppRoutes.isExplicitPostAuthRedirectRoute(
      normalizedRedirect,
    );
    final targetRoute = _openFeedAfterNextAuth && !hasExplicitRedirect
        ? AppRoutes.feed
        : hasExplicitRedirect || AppRoutes.isPostAuthRoute(redirectRoute)
        ? AppRoutes.postAuthRoute(normalizedRedirect)
        : _lastRoute;

    if (_openFeedAfterNextAuth) {
      _openFeedAfterNextAuth = false;
      await _preferences?.remove(_openFeedAfterNextAuthKey);
    }

    await rememberRoute(targetRoute);
    return targetRoute;
  }

  static String _normalizeStoredRoute(String? routeName) {
    return AppRoutes.isRestorable(routeName)
        ? AppRoutes.postAuthRoute(routeName)
        : AppRoutes.feed;
  }
}
