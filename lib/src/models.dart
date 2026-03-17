import 'package:flutter/material.dart';

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  String get storageValue => name;

  static AppThemePreference fromStorage(String? value) {
    return AppThemePreference.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

enum AppUnit { ml, oz }

extension AppUnitX on AppUnit {
  String get storageValue => name;

  static AppUnit fromStorage(String? value) {
    return AppUnit.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => AppUnit.ml,
    );
  }

  double convertFromMl(double value) {
    return switch (this) {
      AppUnit.ml => value,
      AppUnit.oz => value / 29.5735,
    };
  }

  double convertToMl(double value) {
    return switch (this) {
      AppUnit.ml => value,
      AppUnit.oz => value * 29.5735,
    };
  }

  String formatVolume(double? volumeMl) {
    if (volumeMl == null) {
      return '--';
    }
    final converted = convertFromMl(volumeMl);
    final digits = converted >= 100 ? 0 : 1;
    return '${converted.toStringAsFixed(digits)} $name';
  }
}

enum DrinkCategory { beer, wine, spirits, cocktails, nonAlcoholic }

extension DrinkCategoryX on DrinkCategory {
  String get storageValue => name;

  static DrinkCategory fromStorage(String value) {
    return DrinkCategory.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => DrinkCategory.nonAlcoholic,
    );
  }

  IconData get icon => switch (this) {
        DrinkCategory.beer => Icons.sports_bar_rounded,
        DrinkCategory.wine => Icons.wine_bar_rounded,
        DrinkCategory.spirits => Icons.local_bar_rounded,
        DrinkCategory.cocktails => Icons.celebration_rounded,
        DrinkCategory.nonAlcoholic => Icons.water_drop_rounded,
      };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.nickname,
    required this.displayName,
    this.profileImagePath,
    this.birthday,
  });

  final String id;
  final String email;
  final String password;
  final String nickname;
  final String displayName;
  final String? profileImagePath;
  final DateTime? birthday;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return 'GT';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.characters.first.toUpperCase();
    final second = parts.length > 1 ? parts[1].characters.first.toUpperCase() : '';
    return '$first$second';
  }

  AppUser copyWith({
    String? nickname,
    String? displayName,
    String? profileImagePath,
    bool clearProfileImage = false,
    DateTime? birthday,
    bool clearBirthday = false,
  }) {
    return AppUser(
      id: id,
      email: email,
      password: password,
      nickname: nickname ?? this.nickname,
      displayName: displayName ?? this.displayName,
      profileImagePath: clearProfileImage ? null : profileImagePath ?? this.profileImagePath,
      birthday: clearBirthday ? null : birthday ?? this.birthday,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'password': password,
      'nickname': nickname,
      'displayName': displayName,
      'profileImagePath': profileImagePath,
      'birthday': birthday?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      nickname: json['nickname'] as String,
      displayName: json['displayName'] as String,
      profileImagePath: json['profileImagePath'] as String?,
      birthday: json['birthday'] == null ? null : DateTime.parse(json['birthday'] as String),
    );
  }
}

class DrinkDefinition {
  const DrinkDefinition({
    required this.id,
    required this.name,
    required this.category,
    this.volumeMl,
    this.imagePath,
    this.ownerUserId,
  });

  final String id;
  final String name;
  final DrinkCategory category;
  final double? volumeMl;
  final String? imagePath;
  final String? ownerUserId;

  bool get isCustom => ownerUserId != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category.storageValue,
      'volumeMl': volumeMl,
      'imagePath': imagePath,
      'ownerUserId': ownerUserId,
    };
  }

  factory DrinkDefinition.fromJson(Map<String, dynamic> json) {
    return DrinkDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      category: DrinkCategoryX.fromStorage(json['category'] as String),
      volumeMl: (json['volumeMl'] as num?)?.toDouble(),
      imagePath: json['imagePath'] as String?,
      ownerUserId: json['ownerUserId'] as String?,
    );
  }
}

class DrinkEntry {
  const DrinkEntry({
    required this.id,
    required this.userId,
    required this.drinkId,
    required this.drinkName,
    required this.category,
    required this.consumedAt,
    this.volumeMl,
    this.comment,
    this.imagePath,
  });

  final String id;
  final String userId;
  final String drinkId;
  final String drinkName;
  final DrinkCategory category;
  final DateTime consumedAt;
  final double? volumeMl;
  final String? comment;
  final String? imagePath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'drinkId': drinkId,
      'drinkName': drinkName,
      'category': category.storageValue,
      'consumedAt': consumedAt.toIso8601String(),
      'volumeMl': volumeMl,
      'comment': comment,
      'imagePath': imagePath,
    };
  }

  factory DrinkEntry.fromJson(Map<String, dynamic> json) {
    return DrinkEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      drinkId: json['drinkId'] as String,
      drinkName: json['drinkName'] as String,
      category: DrinkCategoryX.fromStorage(json['category'] as String),
      consumedAt: DateTime.parse(json['consumedAt'] as String),
      volumeMl: (json['volumeMl'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }
}

class UserSettings {
  const UserSettings({
    required this.themePreference,
    required this.localeCode,
    required this.unit,
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      themePreference: AppThemePreference.system,
      localeCode: 'en',
      unit: AppUnit.ml,
    );
  }

  final AppThemePreference themePreference;
  final String localeCode;
  final AppUnit unit;

  UserSettings copyWith({
    AppThemePreference? themePreference,
    String? localeCode,
    AppUnit? unit,
  }) {
    return UserSettings(
      themePreference: themePreference ?? this.themePreference,
      localeCode: localeCode ?? this.localeCode,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themePreference': themePreference.storageValue,
      'localeCode': localeCode,
      'unit': unit.storageValue,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      themePreference: AppThemePreferenceX.fromStorage(json['themePreference'] as String?),
      localeCode: (json['localeCode'] as String?) ?? 'en',
      unit: AppUnitX.fromStorage(json['unit'] as String?),
    );
  }
}

List<DrinkDefinition> buildDefaultDrinkCatalog() {
  const defaults = <(DrinkCategory, String, double?)>[
    (DrinkCategory.beer, 'Pils', 330),
    (DrinkCategory.beer, 'Helles', 500),
    (DrinkCategory.beer, 'Weizen', 500),
    (DrinkCategory.beer, 'Kellerbier', 500),
    (DrinkCategory.beer, 'Kölsch', 200),
    (DrinkCategory.beer, 'Alt', 250),
    (DrinkCategory.beer, 'IPA', 330),
    (DrinkCategory.wine, 'Red Wine', 150),
    (DrinkCategory.wine, 'White Wine', 150),
    (DrinkCategory.wine, 'Rosé Wine', 150),
    (DrinkCategory.wine, 'Sparkling Wine', 120),
    (DrinkCategory.wine, 'Aperol Spritz', 200),
    (DrinkCategory.spirits, 'Vodka', 40),
    (DrinkCategory.spirits, 'Gin', 40),
    (DrinkCategory.spirits, 'Rum', 40),
    (DrinkCategory.spirits, 'Whiskey', 40),
    (DrinkCategory.spirits, 'Tequila', 40),
    (DrinkCategory.cocktails, 'Mojito', 250),
    (DrinkCategory.cocktails, 'Margarita', 180),
    (DrinkCategory.cocktails, 'Martini', 160),
    (DrinkCategory.nonAlcoholic, 'Water', 250),
    (DrinkCategory.nonAlcoholic, 'Juice', 250),
    (DrinkCategory.nonAlcoholic, 'Sparkling Water', 250),
    (DrinkCategory.nonAlcoholic, 'Tea', 300),
    (DrinkCategory.nonAlcoholic, 'Coffee', 200),
    (DrinkCategory.nonAlcoholic, 'Energy Drink', 250),
    (DrinkCategory.nonAlcoholic, 'Cola', 330),
    (DrinkCategory.nonAlcoholic, 'Lemonade', 330),
  ];

  return defaults
      .map(
        (item) => DrinkDefinition(
          id: '${item.$1.storageValue}-${item.$2.toLowerCase().replaceAll(' ', '-')}',
          name: item.$2,
          category: item.$1,
          volumeMl: item.$3,
        ),
      )
      .toList(growable: false);
}
