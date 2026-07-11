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
    // After a logout, the user shouldn't be dropped back onto whatever
    // protected route they were viewing before — except when the app is
    // being launched into an explicit post-auth redirect (e.g. a deep link
    // for after they sign back in), which should still be honored.
    if (_openFeedAfterNextAuth &&
        AppRoutes.isExplicitPostAuthRedirectRoute(normalizedRequested)) {
      return normalizedRequested;
    }

    if (_openFeedAfterNextAuth) {
      return AppRoutes.auth;
    }

    return switch (normalizedRequested) {
      // Root/auth/feed aren't meaningful "requested" destinations on their
      // own (root is just the app's entry point, auth/feed are generic
      // landing points) — restore whatever route the user was actually on.
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
    // Both flag and route are persisted (not just kept in memory) so the
    // "land on feed after next sign-in" behavior survives an app restart
    // that happens while still logged out.
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
    // Priority: an explicit redirect (e.g. from a deep link that required
    // signing in first) always wins; otherwise, if the user just logged
    // out, send them to feed rather than back to whatever route they left;
    // otherwise fall back to whatever route was remembered before auth.
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
