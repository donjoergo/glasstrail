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

enum DrinkCategory {
  beer,
  wine,
  sparklingWines,
  longdrinks,
  spirits,
  shots,
  cocktails,
  appleWines,
  nonAlcoholic,
}

extension DrinkCategoryX on DrinkCategory {
  String get storageValue => name;

  static DrinkCategory? maybeFromStorage(String? value) {
    for (final candidate in DrinkCategory.values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
    return null;
  }

  static DrinkCategory fromStorage(String value) {
    return maybeFromStorage(value) ?? DrinkCategory.nonAlcoholic;
  }

  IconData get icon => switch (this) {
    DrinkCategory.beer => Icons.sports_bar_rounded,
    DrinkCategory.wine => Icons.wine_bar_rounded,
    DrinkCategory.sparklingWines => Icons.wine_bar_rounded,
    DrinkCategory.longdrinks => Icons.local_bar_rounded,
    DrinkCategory.spirits => Icons.local_bar_rounded,
    DrinkCategory.shots => Icons.liquor_rounded,
    DrinkCategory.cocktails => Icons.celebration_rounded,
    DrinkCategory.appleWines => Icons.wine_bar_rounded,
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
  return localPart.isEmpty ? 'Glass Trail User' : localPart;
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
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
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
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;

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
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    bool clearLocation = false,
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
      locationLatitude: clearLocation
          ? null
          : locationLatitude ?? this.locationLatitude,
      locationLongitude: clearLocation
          ? null
          : locationLongitude ?? this.locationLongitude,
      locationAddress: clearLocation
          ? null
          : locationAddress ?? this.locationAddress,
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
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'locationAddress': locationAddress,
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
      volumeMl: _readDouble(json, 'volumeMl', 'volume_ml'),
      comment: json['comment'] as String?,
      imagePath: json['imagePath'] as String?,
      locationLatitude: _readDouble(
        json,
        'locationLatitude',
        'location_latitude',
      ),
      locationLongitude: _readDouble(
        json,
        'locationLongitude',
        'location_longitude',
      ),
      locationAddress: _readString(json, 'locationAddress', 'location_address'),
    );
  }
}

class UserSettings {
  const UserSettings({
    required this.themePreference,
    required this.localeCode,
    required this.unit,
    required this.handedness,
    this.hiddenGlobalDrinkIds = const <String>[],
    this.hiddenGlobalDrinkCategories = const <DrinkCategory>[],
    this.globalDrinkOrderOverrides = const <DrinkCategory, List<String>>{},
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      themePreference: AppThemePreference.system,
      localeCode: 'en',
      unit: AppUnit.ml,
      handedness: AppHandedness.right,
      hiddenGlobalDrinkIds: <String>[],
      hiddenGlobalDrinkCategories: <DrinkCategory>[],
      globalDrinkOrderOverrides: <DrinkCategory, List<String>>{},
    );
  }

  final AppThemePreference themePreference;
  final String localeCode;
  final AppUnit unit;
  final AppHandedness handedness;
  final List<String> hiddenGlobalDrinkIds;
  final List<DrinkCategory> hiddenGlobalDrinkCategories;
  final Map<DrinkCategory, List<String>> globalDrinkOrderOverrides;

  UserSettings copyWith({
    AppThemePreference? themePreference,
    String? localeCode,
    AppUnit? unit,
    AppHandedness? handedness,
    List<String>? hiddenGlobalDrinkIds,
    List<DrinkCategory>? hiddenGlobalDrinkCategories,
    Map<DrinkCategory, List<String>>? globalDrinkOrderOverrides,
  }) {
    return UserSettings(
      themePreference: themePreference ?? this.themePreference,
      localeCode: localeCode ?? this.localeCode,
      unit: unit ?? this.unit,
      handedness: handedness ?? this.handedness,
      hiddenGlobalDrinkIds: hiddenGlobalDrinkIds ?? this.hiddenGlobalDrinkIds,
      hiddenGlobalDrinkCategories:
          hiddenGlobalDrinkCategories ?? this.hiddenGlobalDrinkCategories,
      globalDrinkOrderOverrides:
          globalDrinkOrderOverrides ?? this.globalDrinkOrderOverrides,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themePreference': themePreference.storageValue,
      'localeCode': localeCode,
      'unit': unit.storageValue,
      'handedness': handedness.storageValue,
      'hiddenGlobalDrinkIds': hiddenGlobalDrinkIds.toList(growable: false),
      'hiddenGlobalDrinkCategories': hiddenGlobalDrinkCategories
          .map((category) => category.storageValue)
          .toList(growable: false),
      'globalDrinkOrderOverrides': <String, List<String>>{
        for (final entry in globalDrinkOrderOverrides.entries)
          entry.key.storageValue: entry.value.toList(growable: false),
      },
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
      hiddenGlobalDrinkIds: _readStringList(
        json,
        'hiddenGlobalDrinkIds',
        'hidden_global_drink_ids',
      ),
      hiddenGlobalDrinkCategories: _readDrinkCategoryList(
        json,
        'hiddenGlobalDrinkCategories',
        'hidden_global_drink_categories',
      ),
      globalDrinkOrderOverrides: _readDrinkOrderOverrides(
        json,
        'globalDrinkOrderOverrides',
        'global_drink_order_overrides',
      ),
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

double? _readDouble(
  Map<String, dynamic> json,
  String primary, [
  String? fallback,
]) {
  final primaryValue = json[primary] as num?;
  if (primaryValue != null) {
    return primaryValue.toDouble();
  }
  if (fallback == null) {
    return null;
  }
  final fallbackValue = json[fallback] as num?;
  return fallbackValue?.toDouble();
}

List<String> _readStringList(
  Map<String, dynamic> json,
  String primary, [
  String? fallback,
]) {
  final value = json[primary] ?? (fallback == null ? null : json[fallback]);
  if (value is! List) {
    return const <String>[];
  }
  final result = <String>[];
  for (final item in value) {
    if (item is String && item.isNotEmpty && !result.contains(item)) {
      result.add(item);
    }
  }
  return result;
}

List<DrinkCategory> _readDrinkCategoryList(
  Map<String, dynamic> json,
  String primary, [
  String? fallback,
]) {
  final value = json[primary] ?? (fallback == null ? null : json[fallback]);
  if (value is! List) {
    return const <DrinkCategory>[];
  }
  final result = <DrinkCategory>[];
  for (final item in value) {
    if (item is! String) {
      continue;
    }
    final category = DrinkCategoryX.maybeFromStorage(item);
    if (category != null && !result.contains(category)) {
      result.add(category);
    }
  }
  return result;
}

Map<DrinkCategory, List<String>> _readDrinkOrderOverrides(
  Map<String, dynamic> json,
  String primary, [
  String? fallback,
]) {
  final rawValue = json[primary] ?? (fallback == null ? null : json[fallback]);
  if (rawValue is! Map) {
    return const <DrinkCategory, List<String>>{};
  }

  final result = <DrinkCategory, List<String>>{};
  for (final entry in rawValue.entries) {
    final category = DrinkCategoryX.maybeFromStorage(
      entry.key is String ? entry.key as String : null,
    );
    if (category == null || entry.value is! List) {
      continue;
    }
    final orderedIds = <String>[];
    for (final item in entry.value as List<dynamic>) {
      if (item is String && item.isNotEmpty && !orderedIds.contains(item)) {
        orderedIds.add(item);
      }
    }
    if (orderedIds.isNotEmpty) {
      result[category] = orderedIds;
    }
  }
  return result;
}

List<DrinkDefinition> buildDefaultDrinkCatalog() {
  const defaults = <(String, DrinkCategory, String, String, double?)>[
    ('beer-pils', DrinkCategory.beer, 'Pils', 'Pils', 330),
    ('beer-helles', DrinkCategory.beer, 'Helles', 'Helles', 500),
    ('beer-weizen', DrinkCategory.beer, 'Weizen', 'Weizen', 500),
    ('beer-kellerbier', DrinkCategory.beer, 'Kellerbier', 'Kellerbier', 500),
    ('beer-kölsch', DrinkCategory.beer, 'Kölsch', 'Kölsch', 200),
    ('beer-alt', DrinkCategory.beer, 'Alt', 'Alt', 250),
    ('beer-ipa', DrinkCategory.beer, 'IPA', 'IPA', 330),
    ('beer-goassmass', DrinkCategory.beer, 'Goaßmaß', 'Goaßmaß', 1000),
    ('beer-mass', DrinkCategory.beer, 'Maß', 'Maß', 1000),
    ('beer-stout', DrinkCategory.beer, 'Stout', 'Stout', 330),
    ('beer-radler', DrinkCategory.beer, 'Radler', 'Radler', 500),
    ('wine-red-wine', DrinkCategory.wine, 'Red Wine', 'Rotwein', 150),
    ('wine-white-wine', DrinkCategory.wine, 'White Wine', 'Weißwein', 150),
    ('wine-rosé-wine', DrinkCategory.wine, 'Rosé Wine', 'Roséwein', 150),
    (
      'wine-aperol-spritz',
      DrinkCategory.wine,
      'Aperol Spritz',
      'Aperol Spritz',
      200,
    ),
    ('wine-mulled-wine', DrinkCategory.wine, 'Mulled Wine', 'Glühwein', 200),
    (
      'wine-wine-spritzer',
      DrinkCategory.wine,
      'Wine Spritzer',
      'Weinschorle',
      250,
    ),
    ('wine-spritzer', DrinkCategory.wine, 'Spritzer', 'Spritzer', 250),
    ('wine-sangria', DrinkCategory.wine, 'Sangria', 'Sangria', 250),
    (
      'wine-sparkling-wine',
      DrinkCategory.sparklingWines,
      'Sparkling Wine',
      'Sekt',
      120,
    ),
    (
      'sparklingWines-champagne',
      DrinkCategory.sparklingWines,
      'Champagne',
      'Champagner',
      120,
    ),
    (
      'longdrinks-cuba-libre',
      DrinkCategory.longdrinks,
      'Cuba Libre',
      'Cuba Libre',
      250,
    ),
    (
      'longdrinks-gin-tonic',
      DrinkCategory.longdrinks,
      'Gin & Tonic',
      'Gin & Tonic',
      250,
    ),
    (
      'longdrinks-jacki-cola',
      DrinkCategory.longdrinks,
      'Jacki Cola',
      'Jacki Cola',
      250,
    ),
    ('longdrinks-vodka-o', DrinkCategory.longdrinks, 'Vodka O', 'Vodka O', 250),
    (
      'longdrinks-vodka-bull',
      DrinkCategory.longdrinks,
      'Vodka Bull',
      'Vodka Bull',
      250,
    ),
    (
      'longdrinks-longdrink',
      DrinkCategory.longdrinks,
      'Longdrink',
      'Longdrink',
      null,
    ),
    ('spirits-vodka', DrinkCategory.spirits, 'Vodka', 'Wodka', 40),
    ('spirits-gin', DrinkCategory.spirits, 'Gin', 'Gin', 40),
    ('spirits-rum', DrinkCategory.spirits, 'Rum', 'Rum', 40),
    ('spirits-whiskey', DrinkCategory.spirits, 'Whiskey', 'Whiskey', 40),
    ('spirits-cognac', DrinkCategory.spirits, 'Cognac', 'Cognac', 40),
    (
      'shots-jaegermeister',
      DrinkCategory.shots,
      'Jägermeister',
      'Jägermeister',
      20,
    ),
    (
      'shots-berliner-luft',
      DrinkCategory.shots,
      'Berliner Luft',
      'Berliner Luft',
      20,
    ),
    ('shots-pfeffi', DrinkCategory.shots, 'Pfeffi', 'Pfeffi', 20),
    ('shots-ficken', DrinkCategory.shots, 'Ficken', 'Ficken', 20),
    ('spirits-tequila', DrinkCategory.shots, 'Tequila', 'Tequila', 40),
    ('shots-limoncello', DrinkCategory.shots, 'Limoncello', 'Limoncello', 20),
    ('cocktails-mojito', DrinkCategory.cocktails, 'Mojito', 'Mojito', 250),
    (
      'cocktails-margarita',
      DrinkCategory.cocktails,
      'Margarita',
      'Margarita',
      180,
    ),
    ('cocktails-martini', DrinkCategory.cocktails, 'Martini', 'Martini', 160),
    (
      'cocktails-cocktail',
      DrinkCategory.cocktails,
      'Cocktail',
      'Cocktail',
      250,
    ),
    (
      'cocktails-caipirinha',
      DrinkCategory.cocktails,
      'Caipirinha',
      'Caipirinha',
      250,
    ),
    (
      'appleWines-hard-seltzer',
      DrinkCategory.appleWines,
      'Hard Seltzer',
      'Hard Seltzer',
      330,
    ),
    (
      'appleWines-apple-wine',
      DrinkCategory.appleWines,
      'Apple Wine',
      'Apfelwein',
      500,
    ),
    ('appleWines-cider', DrinkCategory.appleWines, 'Cider', 'Cider', 330),
    ('nonAlcoholic-water', DrinkCategory.nonAlcoholic, 'Water', 'Wasser', 250),
    ('nonAlcoholic-juice', DrinkCategory.nonAlcoholic, 'Juice', 'Saft', 250),
    (
      'nonAlcoholic-sparkling-water',
      DrinkCategory.nonAlcoholic,
      'Sparkling Water',
      'Sprudelwasser',
      250,
    ),
    ('nonAlcoholic-tea', DrinkCategory.nonAlcoholic, 'Tea', 'Tee', 300),
    (
      'nonAlcoholic-coffee',
      DrinkCategory.nonAlcoholic,
      'Coffee',
      'Kaffee',
      200,
    ),
    (
      'nonAlcoholic-energy-drink',
      DrinkCategory.nonAlcoholic,
      'Energy Drink',
      'Energy Drink',
      250,
    ),
    ('nonAlcoholic-cola', DrinkCategory.nonAlcoholic, 'Cola', 'Cola', 330),
    (
      'nonAlcoholic-lemonade',
      DrinkCategory.nonAlcoholic,
      'Lemonade',
      'Limonade',
      330,
    ),
  ];

  return defaults
      .map(
        (item) => DrinkDefinition(
          id: item.$1,
          category: item.$2,
          name: item.$3,
          localizedNameDe: item.$4,
          volumeMl: item.$5,
        ),
      )
      .toList(growable: false);
}
