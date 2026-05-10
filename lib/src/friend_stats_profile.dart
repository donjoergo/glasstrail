import 'package:flutter/widgets.dart';

import 'stats_calculator.dart';

class FriendStatsProfile {
  const FriendStatsProfile({
    required this.id,
    required this.displayName,
    this.profileImagePath,
    required this.shareStatsWithFriends,
    this.statistics,
  });

  final String id;
  final String displayName;
  final String? profileImagePath;
  final bool shareStatsWithFriends;
  final AppStatistics? statistics;

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'profileImagePath': profileImagePath,
      'shareStatsWithFriends': shareStatsWithFriends,
      'statistics': statistics?.toJson(),
    };
  }

  factory FriendStatsProfile.fromJson(Map<String, dynamic> json) {
    return FriendStatsProfile(
      id: json['id'] as String,
      displayName:
          (json['displayName'] as String?) ??
          (json['display_name'] as String?) ??
          'Glass Trail User',
      profileImagePath:
          (json['profileImagePath'] as String?) ??
          (json['profile_image_path'] as String?),
      shareStatsWithFriends:
          (json['shareStatsWithFriends'] as bool?) ??
          (json['share_stats_with_friends'] as bool?) ??
          true,
      statistics: json['statistics'] is Map
          ? AppStatistics.fromJson(
              Map<String, dynamic>.from(json['statistics'] as Map),
            )
          : null,
    );
  }
}
