import '../models.dart';

class BootstrapSnapshot {
  const BootstrapSnapshot({
    this.currentUser,
    this.defaultCatalog = const <DrinkDefinition>[],
    this.customDrinks = const <DrinkDefinition>[],
    this.entries = const <DrinkEntry>[],
    this.firstFeedPage,
    this.settings,
    this.friendConnections = const <FriendConnection>[],
    this.notifications = const <AppNotification>[],
  });

  final AppUser? currentUser;
  final List<DrinkDefinition> defaultCatalog;
  final List<DrinkDefinition> customDrinks;
  final List<DrinkEntry> entries;
  final FeedDrinkPostPage? firstFeedPage;
  final UserSettings? settings;
  final List<FriendConnection> friendConnections;
  final List<AppNotification> notifications;

  BootstrapSnapshot copyWith({
    AppUser? currentUser,
    bool clearCurrentUser = false,
    List<DrinkDefinition>? defaultCatalog,
    List<DrinkDefinition>? customDrinks,
    List<DrinkEntry>? entries,
    FeedDrinkPostPage? firstFeedPage,
    bool clearFirstFeedPage = false,
    UserSettings? settings,
    bool clearSettings = false,
    List<FriendConnection>? friendConnections,
    List<AppNotification>? notifications,
  }) {
    return BootstrapSnapshot(
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      defaultCatalog: defaultCatalog ?? this.defaultCatalog,
      customDrinks: customDrinks ?? this.customDrinks,
      entries: entries ?? this.entries,
      firstFeedPage: clearFirstFeedPage
          ? null
          : firstFeedPage ?? this.firstFeedPage,
      settings: clearSettings ? null : settings ?? this.settings,
      friendConnections: friendConnections ?? this.friendConnections,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentUser': currentUser?.toJson(),
      'defaultCatalog': defaultCatalog
          .map((drink) => drink.toJson())
          .toList(growable: false),
      'customDrinks': customDrinks
          .map((drink) => drink.toJson())
          .toList(growable: false),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'firstFeedPage': firstFeedPage?.toJson(),
      'settings': settings?.toJson(),
      'friendConnections': friendConnections
          .map((connection) => connection.toJson())
          .toList(growable: false),
      'notifications': notifications
          .map((notification) => notification.toJson())
          .toList(growable: false),
    };
  }

  factory BootstrapSnapshot.fromJson(Map<String, dynamic> json) {
    return BootstrapSnapshot(
      currentUser: json['currentUser'] is Map
          ? AppUser.fromJson(
              Map<String, dynamic>.from(json['currentUser'] as Map),
            )
          : null,
      defaultCatalog:
          (json['defaultCatalog'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (drink) => DrinkDefinition.fromJson(
                  Map<String, dynamic>.from(drink as Map),
                ),
              )
              .toList(growable: false),
      customDrinks:
          (json['customDrinks'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (drink) => DrinkDefinition.fromJson(
                  Map<String, dynamic>.from(drink as Map),
                ),
              )
              .toList(growable: false),
      entries: (json['entries'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (entry) =>
                DrinkEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(growable: false),
      firstFeedPage: json['firstFeedPage'] is Map
          ? FeedDrinkPostPage.fromJson(
              Map<String, dynamic>.from(json['firstFeedPage'] as Map),
            )
          : null,
      settings: json['settings'] is Map
          ? UserSettings.fromJson(
              Map<String, dynamic>.from(json['settings'] as Map),
            )
          : null,
      friendConnections:
          (json['friendConnections'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (connection) => FriendConnection.fromJson(
                  Map<String, dynamic>.from(connection as Map),
                ),
              )
              .toList(growable: false),
      notifications:
          (json['notifications'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (notification) => AppNotification.fromJson(
                  Map<String, dynamic>.from(notification as Map),
                ),
              )
              .toList(growable: false),
    );
  }
}
