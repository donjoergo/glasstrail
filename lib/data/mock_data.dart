import 'package:glasstrail/models/app_models.dart';

class MockData {
  static const AppUser me = AppUser(
    id: 'user_me',
    nickname: 'hops_hiker',
    displayName: 'Alex Hopper',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
  );

  static List<Friend> friends() {
    return const [
      Friend(
        id: 'friend_1',
        name: 'Mia',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
      ),
      Friend(
        id: 'friend_2',
        name: 'Jonas',
        avatarUrl: 'https://i.pravatar.cc/150?img=8',
      ),
      Friend(
        id: 'friend_3',
        name: 'Lea',
        avatarUrl: 'https://i.pravatar.cc/150?img=32',
        status: FriendshipStatus.incomingRequest,
      ),
      Friend(
        id: 'friend_4',
        name: 'Noah',
        avatarUrl: 'https://i.pravatar.cc/150?img=40',
        status: FriendshipStatus.outgoingRequest,
      ),
    ];
  }

  static List<DrinkType> globalCatalog() {
    return const [
      DrinkType(
        id: 'beer_pils',
        name: 'Pils',
        category: DrinkCategory.beer,
        imageUrl: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?w=1200',
        volumeMl: 500,
      ),
      DrinkType(
        id: 'beer_ipa',
        name: 'IPA',
        category: DrinkCategory.beer,
        imageUrl: 'https://images.unsplash.com/photo-1514361892635-6b07e31e75f9?w=1200',
        volumeMl: 500,
      ),
      DrinkType(
        id: 'wine_red',
        name: 'Red Wine',
        category: DrinkCategory.wine,
        imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=1200',
        volumeMl: 200,
      ),
      DrinkType(
        id: 'wine_sparkling',
        name: 'Sparkling Wine',
        category: DrinkCategory.wine,
        imageUrl: 'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=1200',
        volumeMl: 200,
      ),
      DrinkType(
        id: 'spirits_gin',
        name: 'Gin',
        category: DrinkCategory.spirits,
        imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=1200',
        volumeMl: 40,
      ),
      DrinkType(
        id: 'spirits_whiskey',
        name: 'Whiskey',
        category: DrinkCategory.spirits,
        imageUrl: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=1200',
        volumeMl: 40,
      ),
      DrinkType(
        id: 'cocktail_mojito',
        name: 'Mojito',
        category: DrinkCategory.cocktails,
        imageUrl: 'https://images.unsplash.com/photo-1560508179-b2c9a2f8f4f8?w=1200',
        volumeMl: 300,
      ),
      DrinkType(
        id: 'cocktail_martini',
        name: 'Martini',
        category: DrinkCategory.cocktails,
        imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=1200',
        volumeMl: 180,
      ),
      DrinkType(
        id: 'non_water',
        name: 'Water',
        category: DrinkCategory.nonAlcoholic,
        imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=1200',
        volumeMl: 400,
      ),
      DrinkType(
        id: 'non_coffee',
        name: 'Coffee',
        category: DrinkCategory.nonAlcoholic,
        imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200',
        volumeMl: 250,
      ),
      DrinkType(
        id: 'non_energy',
        name: 'Energy Drink',
        category: DrinkCategory.nonAlcoholic,
        imageUrl: 'https://images.unsplash.com/photo-1622484212850-eb596d769edc?w=1200',
        volumeMl: 330,
      ),
    ];
  }

  static List<DrinkLog> initialLogs() {
    final now = DateTime.now();
    return [
      DrinkLog(
        id: 'log_1',
        userId: me.id,
        userName: me.displayName,
        userAvatarUrl: me.avatarUrl,
        drinkName: 'IPA',
        category: DrinkCategory.beer,
        loggedAt: now.subtract(const Duration(hours: 2)),
        latitude: 52.5205,
        longitude: 13.4095,
        comment: 'Post-work meetup',
        imageUrl:
            'https://images.unsplash.com/photo-1514361892635-6b07e31e75f9?w=1200',
        taggedFriends: ['friend_1'],
        cheersCount: 2,
        commentCount: 1,
      ),
      DrinkLog(
        id: 'log_2',
        userId: 'friend_1',
        userName: 'Mia',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
        drinkName: 'Mojito',
        category: DrinkCategory.cocktails,
        loggedAt: now.subtract(const Duration(hours: 6)),
        latitude: 52.5161,
        longitude: 13.3777,
        comment: 'Sunset drink',
        cheersCount: 5,
        commentCount: 2,
      ),
      DrinkLog(
        id: 'log_3',
        userId: 'friend_2',
        userName: 'Jonas',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
        drinkName: 'Sparkling Water',
        category: DrinkCategory.nonAlcoholic,
        loggedAt: now.subtract(const Duration(days: 1, hours: 3)),
        latitude: 52.4993,
        longitude: 13.4181,
        cheersCount: 1,
      ),
      DrinkLog(
        id: 'log_4',
        userId: me.id,
        userName: me.displayName,
        userAvatarUrl: me.avatarUrl,
        drinkName: 'Coffee',
        category: DrinkCategory.nonAlcoholic,
        loggedAt: now.subtract(const Duration(days: 2, hours: 1)),
        latitude: 52.5222,
        longitude: 13.4025,
        comment: 'Morning focus',
        cheersCount: 0,
        commentCount: 0,
      ),
      DrinkLog(
        id: 'log_5',
        userId: me.id,
        userName: me.displayName,
        userAvatarUrl: me.avatarUrl,
        drinkName: 'Red Wine',
        category: DrinkCategory.wine,
        loggedAt: now.subtract(const Duration(days: 4)),
        latitude: 52.5159,
        longitude: 13.401,
        cheersCount: 3,
        commentCount: 1,
      ),
    ];
  }

  static List<BadgeAward> initialBadges() {
    final now = DateTime.now();
    return [
      BadgeAward(
        id: 'badge_first_sip',
        name: 'First Sip',
        description: 'Logged your first drink',
        unlockedAt: now.subtract(const Duration(days: 10)),
      ),
      BadgeAward(
        id: 'badge_social_sipper',
        name: 'Social Sipper',
        description: 'Logged 10 drinks',
        unlockedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static List<FeedItem> initialFeed(
    List<DrinkLog> logs,
    List<BadgeAward> badges,
  ) {
    return [
      FeedItem(
        id: 'feed_${logs[0].id}',
        type: FeedEventType.drinkLogged,
        createdAt: logs[0].loggedAt,
        log: logs[0],
      ),
      FeedItem(
        id: 'feed_badge_bundle_1',
        type: FeedEventType.badgesUnlocked,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        badges: [badges[1]],
      ),
      FeedItem(
        id: 'feed_${logs[1].id}',
        type: FeedEventType.drinkLogged,
        createdAt: logs[1].loggedAt,
        log: logs[1],
      ),
      FeedItem(
        id: 'feed_${logs[2].id}',
        type: FeedEventType.drinkLogged,
        createdAt: logs[2].loggedAt,
        log: logs[2],
      ),
      FeedItem(
        id: 'feed_${logs[3].id}',
        type: FeedEventType.drinkLogged,
        createdAt: logs[3].loggedAt,
        log: logs[3],
      ),
    ];
  }
}
