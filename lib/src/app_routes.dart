class AppRoutes {
  static const root = '/';
  static const auth = '/auth';
  static const feed = '/feed';
  static const statistics = '/statistics';
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
      profile ||
      addDrink ||
      editProfile => routeName!,
      _ => root,
    };
  }

  static int homeTabIndex(String routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      root || feed => 0,
      statistics => 1,
      profile => 2,
      _ => 0,
    };
  }

  static String homeRouteForIndex(int index) {
    return switch (index) {
      0 => feed,
      1 => statistics,
      2 => profile,
      _ => feed,
    };
  }
}
