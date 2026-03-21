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

  static Future<RouteMemory> create() async {
    final preferences = await SharedPreferences.getInstance();
    return RouteMemory._(preferences);
  }

  String resolveInitialRoute(String? requestedRoute) {
    if (_openFeedAfterNextAuth) {
      return AppRoutes.auth;
    }

    final normalizedRequested = AppRoutes.normalize(requestedRoute);
    return switch (normalizedRequested) {
      AppRoutes.root || AppRoutes.auth || AppRoutes.feed => _lastRoute,
      _ when AppRoutes.isRestorable(normalizedRequested) => normalizedRequested,
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
    final targetRoute = _openFeedAfterNextAuth
        ? AppRoutes.feed
        : AppRoutes.isRestorable(redirectRoute)
        ? AppRoutes.postAuthRoute(redirectRoute)
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
