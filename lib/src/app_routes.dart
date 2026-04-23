class AppRoutes {
  static const root = '/';
  static const auth = '/auth';
  static const feed = '/feed';
  static const statistics = '/statistics';
  static const statisticsOverview = '/statistics/overview';
  static const statisticsMap = '/statistics/map';
  static const statisticsGallery = '/statistics/gallery';
  static const statisticsHistory = '/statistics/history';
  static const bar = '/bar';
  static const barSorting = '/bar/sorting';
  static const barCustom = '/bar/custom';
  static const profile = '/profile';
  static const friendProfilePrefix = '/friends/profile/';
  static const addDrink = '/add-drink';
  static const editProfile = '/profile/edit';

  static String normalize(String? routeName) {
    final candidate = routeName == null || routeName.isEmpty
        ? root
        : routeName.split('?').first;
    if (isFriendProfileRoute(candidate)) {
      return candidate;
    }
    return switch (routeName) {
      null || '' => root,
      root ||
      auth ||
      feed ||
      statistics ||
      statisticsOverview ||
      statisticsMap ||
      statisticsGallery ||
      statisticsHistory ||
      bar ||
      barSorting ||
      barCustom ||
      profile ||
      addDrink ||
      editProfile => routeName,
      _ => root,
    };
  }

  static String friendProfileRoute(String shareCode) {
    return '$friendProfilePrefix${Uri.encodeComponent(shareCode)}';
  }

  static bool isFriendProfileRoute(String? routeName) {
    final normalized = routeName?.split('?').first ?? '';
    return normalized.startsWith(friendProfilePrefix) &&
        normalized.length > friendProfilePrefix.length;
  }

  static String? friendProfileShareCode(String? routeName) {
    final normalized = normalize(routeName);
    if (!isFriendProfileRoute(normalized)) {
      return null;
    }
    return Uri.decodeComponent(
      normalized.substring(friendProfilePrefix.length),
    );
  }

  static bool isStatisticsRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      statistics ||
      statisticsOverview ||
      statisticsMap ||
      statisticsGallery ||
      statisticsHistory => true,
      _ => false,
    };
  }

  static bool isBarRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      bar || barSorting || barCustom => true,
      _ => false,
    };
  }

  static String homePrimaryRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      root || feed => feed,
      _ when isStatisticsRoute(normalized) => statistics,
      _ when isBarRoute(normalized) => bar,
      profile => profile,
      _ => feed,
    };
  }

  static bool isHomeShellRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      feed || profile => true,
      _ when isStatisticsRoute(normalized) => true,
      _ when isBarRoute(normalized) => true,
      _ => false,
    };
  }

  static String postAuthRoute(String? routeName) {
    final normalized = normalize(routeName);
    if (isFriendProfileRoute(normalized)) {
      return normalized;
    }
    return switch (normalized) {
      feed ||
      statistics ||
      statisticsOverview ||
      statisticsMap ||
      statisticsGallery ||
      statisticsHistory ||
      bar ||
      barSorting ||
      barCustom ||
      profile ||
      addDrink ||
      editProfile => normalized,
      _ => feed,
    };
  }

  static bool isRestorable(String? routeName) {
    final normalized = normalize(routeName);
    if (isFriendProfileRoute(normalized)) {
      return true;
    }
    return switch (normalized) {
      feed ||
      statistics ||
      statisticsOverview ||
      statisticsMap ||
      statisticsGallery ||
      statisticsHistory ||
      bar ||
      barSorting ||
      barCustom ||
      profile ||
      addDrink ||
      editProfile => true,
      _ => false,
    };
  }

  static int statisticsTabIndexForRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      statistics || statisticsOverview => 0,
      statisticsMap => 1,
      statisticsGallery => 2,
      statisticsHistory => 3,
      _ => 0,
    };
  }

  static String statisticsRouteForIndex(int index) {
    return switch (index) {
      0 => statisticsOverview,
      1 => statisticsMap,
      2 => statisticsGallery,
      3 => statisticsHistory,
      _ => statisticsOverview,
    };
  }

  static int barTabIndexForRoute(String? routeName) {
    final normalized = normalize(routeName);
    return switch (normalized) {
      bar || barSorting => 0,
      barCustom => 1,
      _ => 0,
    };
  }

  static String barRouteForIndex(int index) {
    return switch (index) {
      0 => barSorting,
      1 => barCustom,
      _ => barSorting,
    };
  }

  static int homeTabIndex(String routeName) {
    return switch (homePrimaryRoute(routeName)) {
      feed => 0,
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
