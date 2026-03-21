class AppRoutes {
  static const root = '/';
  static const auth = '/auth';
  static const feed = '/feed';
  static const statistics = '/statistics';
  static const bar = '/bar';
  static const profile = '/profile';
  static const addDrink = '/add-drink';
  static const editProfile = '/profile/edit';

  static String normalize(String? routeName) {
    return switch (routeName) {
      null || '' => root,
      root ||
      auth ||
      feed ||
      statistics ||
      bar ||
      profile ||
      addDrink ||
      editProfile => routeName,
      _ => root,
    };
  }

  static String postAuthRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      feed ||
      statistics ||
      bar ||
      profile ||
      addDrink ||
      editProfile => normalized,
      _ => feed,
    };
  }

  static bool isRestorable(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      feed || statistics || bar || profile || addDrink || editProfile => true,
      _ => false,
    };
  }

  static int homeTabIndex(String routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      root || feed => 0,
      statistics => 1,
      bar => 2,
      profile => 3,
      _ => 0,
    };
  }

  static String homeRouteForIndex(int index) {
    return switch (index) {
      0 => feed,
      1 => statistics,
      2 => bar,
      3 => profile,
      _ => feed,
    };
  }
}
