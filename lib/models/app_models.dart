import 'package:flutter/material.dart';

enum DrinkCategory { beer, wine, spirits, cocktails, nonAlcoholic }

extension DrinkCategoryX on DrinkCategory {
  String get key {
    switch (this) {
      case DrinkCategory.beer:
        return 'beer';
      case DrinkCategory.wine:
        return 'wine';
      case DrinkCategory.spirits:
        return 'spirits';
      case DrinkCategory.cocktails:
        return 'cocktails';
      case DrinkCategory.nonAlcoholic:
        return 'nonAlcoholic';
    }
  }

  String get defaultLabel {
    switch (this) {
      case DrinkCategory.beer:
        return 'Beer';
      case DrinkCategory.wine:
        return 'Wine';
      case DrinkCategory.spirits:
        return 'Spirits';
      case DrinkCategory.cocktails:
        return 'Cocktails';
      case DrinkCategory.nonAlcoholic:
        return 'Non-alcoholic';
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.nickname,
    required this.displayName,
    required this.avatarUrl,
  });

  final String id;
  final String nickname;
  final String displayName;
  final String avatarUrl;

  AppUser copyWith({
    String? nickname,
    String? displayName,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      nickname: nickname ?? this.nickname,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

enum FriendshipStatus { accepted, incomingRequest, outgoingRequest }

class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.status = FriendshipStatus.accepted,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final FriendshipStatus status;

  Friend copyWith({
    String? name,
    String? avatarUrl,
    FriendshipStatus? status,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
    );
  }
}

class DrinkType {
  const DrinkType({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.volumeMl,
    this.isGlobal = true,
  });

  final String id;
  final String name;
  final DrinkCategory category;
  final String imageUrl;
  final int? volumeMl;
  final bool isGlobal;
}

class DrinkLog {
  const DrinkLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.drinkName,
    required this.category,
    required this.loggedAt,
    required this.latitude,
    required this.longitude,
    this.comment,
    this.imageUrl,
    this.taggedFriends = const [],
    this.cheersCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String drinkName;
  final DrinkCategory category;
  final DateTime loggedAt;
  final double latitude;
  final double longitude;
  final String? comment;
  final String? imageUrl;
  final List<String> taggedFriends;
  final int cheersCount;
  final int commentCount;

  DrinkLog copyWith({
    int? cheersCount,
    int? commentCount,
  }) {
    return DrinkLog(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      drinkName: drinkName,
      category: category,
      loggedAt: loggedAt,
      latitude: latitude,
      longitude: longitude,
      comment: comment,
      imageUrl: imageUrl,
      taggedFriends: taggedFriends,
      cheersCount: cheersCount ?? this.cheersCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class BadgeAward {
  const BadgeAward({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockedAt,
    this.color = const Color(0xFFF4A261),
  });

  final String id;
  final String name;
  final String description;
  final DateTime unlockedAt;
  final Color color;
}

enum FeedEventType { drinkLogged, badgesUnlocked }

class FeedItem {
  const FeedItem({
    required this.id,
    required this.type,
    required this.createdAt,
    this.log,
    this.badges = const [],
  });

  final String id;
  final FeedEventType type;
  final DateTime createdAt;
  final DrinkLog? log;
  final List<BadgeAward> badges;
}

class LegacyImportRow {
  const LegacyImportRow({
    required this.legacyType,
    required this.mappedType,
    required this.count,
  });

  final String legacyType;
  final String mappedType;
  final int count;
}

class LegacyImportResult {
  const LegacyImportResult({
    required this.totalEntries,
    required this.validEntries,
    required this.errors,
    required this.rows,
  });

  final int totalEntries;
  final int validEntries;
  final List<String> errors;
  final List<LegacyImportRow> rows;

  bool get isValid => errors.isEmpty;
}

enum DateFilter { today, sevenDays, thirtyDays, all }
