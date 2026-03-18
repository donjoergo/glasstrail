import 'package:flutter/material.dart';

import 'birthday.dart';

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
    final digits = _displayFractionDigits(converted);
    return '${converted.toStringAsFixed(digits)} $name';
  }

  String formatVolumeInput(double? volumeMl) {
    if (volumeMl == null) {
      return '';
    }
    final converted = convertFromMl(volumeMl);
    final digits = _displayFractionDigits(converted);
    return converted.toStringAsFixed(digits).replaceFirst(RegExp(r'\.0$'), '');
  }

  int _displayFractionDigits(double convertedValue) {
    return switch (this) {
      AppUnit.ml => 0,
      AppUnit.oz => convertedValue >= 100 ? 0 : 1,
    };
  }
}

enum AppHandedness { right, left }

extension AppHandednessX on AppHandedness {
  String get storageValue => name;

  bool get isLeft => this == AppHandedness.left;

  static AppHandedness fromStorage(String? value) {
    return AppHandedness.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => AppHandedness.right,
    );
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
    this.password,
    required this.displayName,
    this.profileImagePath,
    this.birthday,
  });

  final String id;
  final String email;
  final String? password;
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
    final second = parts.length > 1
        ? parts[1].characters.first.toUpperCase()
        : '';
    return '$first$second';
  }

  AppUser copyWith({
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
      displayName: displayName ?? this.displayName,
      profileImagePath: clearProfileImage
          ? null
          : profileImagePath ?? this.profileImagePath,
      birthday: clearBirthday
          ? null
          : normalizeBirthdayOrNull(birthday ?? this.birthday),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'password': password,
      'displayName': displayName,
      'profileImagePath': profileImagePath,
      'birthday': normalizeBirthdayOrNull(birthday)?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String?,
      displayName: _displayNameFromJson(json),
      profileImagePath: json['profileImagePath'] as String?,
      birthday: normalizeBirthdayOrNull(
        json['birthday'] == null
            ? null
            : DateTime.parse(json['birthday'] as String),
      ),
    );
  }
}

String _displayNameFromJson(Map<String, dynamic> json) {
  final displayName =
      (json['displayName'] as String?) ?? (json['display_name'] as String?);
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }

  final legacyNickname = json['nickname'] as String?;
  if (legacyNickname != null && legacyNickname.trim().isNotEmpty) {
    return legacyNickname.trim();
  }

  final email = (json['email'] as String?)?.trim() ?? '';
  final localPart = email.split('@').first.trim();
  return localPart.isEmpty ? 'GlassTrail User' : localPart;
}

class DrinkDefinition {
  const DrinkDefinition({
    required this.id,
    required this.name,
    required this.category,
    this.localizedNameDe,
    this.volumeMl,
    this.imagePath,
    this.ownerUserId,
  });

  final String id;
  final String name;
  final DrinkCategory category;
  final String? localizedNameDe;
  final double? volumeMl;
  final String? imagePath;
  final String? ownerUserId;

  bool get isCustom => ownerUserId != null;

  String displayName(String localeCode) {
    if (localeCode == 'de') {
      final german = localizedNameDe?.trim();
      if (german != null && german.isNotEmpty) {
        return german;
      }
    }
    return name;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category.storageValue,
      'localizedNameDe': localizedNameDe,
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
      localizedNameDe:
          (json['localizedNameDe'] as String?) ??
          (json['localized_name_de'] as String?),
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

  DrinkEntry copyWith({
    String? drinkId,
    String? drinkName,
    DrinkCategory? category,
    DateTime? consumedAt,
    double? volumeMl,
    String? comment,
    bool clearComment = false,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return DrinkEntry(
      id: id,
      userId: userId,
      drinkId: drinkId ?? this.drinkId,
      drinkName: drinkName ?? this.drinkName,
      category: category ?? this.category,
      consumedAt: consumedAt ?? this.consumedAt,
      volumeMl: volumeMl ?? this.volumeMl,
      comment: clearComment ? null : comment ?? this.comment,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    );
  }

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
    required this.handedness,
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      themePreference: AppThemePreference.system,
      localeCode: 'en',
      unit: AppUnit.ml,
      handedness: AppHandedness.right,
    );
  }

  final AppThemePreference themePreference;
  final String localeCode;
  final AppUnit unit;
  final AppHandedness handedness;

  UserSettings copyWith({
    AppThemePreference? themePreference,
    String? localeCode,
    AppUnit? unit,
    AppHandedness? handedness,
  }) {
    return UserSettings(
      themePreference: themePreference ?? this.themePreference,
      localeCode: localeCode ?? this.localeCode,
      unit: unit ?? this.unit,
      handedness: handedness ?? this.handedness,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themePreference': themePreference.storageValue,
      'localeCode': localeCode,
      'unit': unit.storageValue,
      'handedness': handedness.storageValue,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      themePreference: AppThemePreferenceX.fromStorage(
        _readString(json, 'themePreference', 'theme_preference'),
      ),
      localeCode: _readString(json, 'localeCode', 'locale_code') ?? 'en',
      unit: AppUnitX.fromStorage(_readString(json, 'unit')),
      handedness: AppHandednessX.fromStorage(_readString(json, 'handedness')),
    );
  }
}

String? _readString(
  Map<String, dynamic> json,
  String primary, [
  String? fallback,
]) {
  final primaryValue = json[primary] as String?;
  if (primaryValue != null) {
    return primaryValue;
  }
  if (fallback == null) {
    return null;
  }
  return json[fallback] as String?;
}

List<DrinkDefinition> buildDefaultDrinkCatalog() {
  const defaults = <(DrinkCategory, String, String, double?)>[
    (DrinkCategory.beer, 'Pils', 'Pils', 330),
    (DrinkCategory.beer, 'Helles', 'Helles', 500),
    (DrinkCategory.beer, 'Weizen', 'Weizen', 500),
    (DrinkCategory.beer, 'Kellerbier', 'Kellerbier', 500),
    (DrinkCategory.beer, 'Kölsch', 'Kölsch', 200),
    (DrinkCategory.beer, 'Alt', 'Alt', 250),
    (DrinkCategory.beer, 'IPA', 'IPA', 330),
    (DrinkCategory.wine, 'Red Wine', 'Rotwein', 150),
    (DrinkCategory.wine, 'White Wine', 'Weißwein', 150),
    (DrinkCategory.wine, 'Rosé Wine', 'Roséwein', 150),
    (DrinkCategory.wine, 'Sparkling Wine', 'Sekt', 120),
    (DrinkCategory.wine, 'Aperol Spritz', 'Aperol Spritz', 200),
    (DrinkCategory.spirits, 'Vodka', 'Wodka', 40),
    (DrinkCategory.spirits, 'Gin', 'Gin', 40),
    (DrinkCategory.spirits, 'Rum', 'Rum', 40),
    (DrinkCategory.spirits, 'Whiskey', 'Whiskey', 40),
    (DrinkCategory.spirits, 'Tequila', 'Tequila', 40),
    (DrinkCategory.cocktails, 'Mojito', 'Mojito', 250),
    (DrinkCategory.cocktails, 'Margarita', 'Margarita', 180),
    (DrinkCategory.cocktails, 'Martini', 'Martini', 160),
    (DrinkCategory.nonAlcoholic, 'Water', 'Wasser', 250),
    (DrinkCategory.nonAlcoholic, 'Juice', 'Saft', 250),
    (DrinkCategory.nonAlcoholic, 'Sparkling Water', 'Sprudelwasser', 250),
    (DrinkCategory.nonAlcoholic, 'Tea', 'Tee', 300),
    (DrinkCategory.nonAlcoholic, 'Coffee', 'Kaffee', 200),
    (DrinkCategory.nonAlcoholic, 'Energy Drink', 'Energy Drink', 250),
    (DrinkCategory.nonAlcoholic, 'Cola', 'Cola', 330),
    (DrinkCategory.nonAlcoholic, 'Lemonade', 'Limonade', 330),
  ];

  return defaults
      .map(
        (item) => DrinkDefinition(
          id: '${item.$1.storageValue}-${item.$2.toLowerCase().replaceAll(' ', '-')}',
          name: item.$2,
          localizedNameDe: item.$3,
          category: item.$1,
          volumeMl: item.$4,
        ),
      )
      .toList(growable: false);
}
