import '../models.dart';

abstract class AppRepository {
  String get backendLabel;
  bool get usesRemoteBackend;

  Future<AppUser?> restoreSession();

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<AppUser> updateProfile(AppUser user);

  Future<List<FriendConnection>> loadFriendConnections(String userId);

  Future<FriendProfile> getOwnFriendProfile(String userId);

  Future<PublicFriendProfile> resolvePublicFriendProfileLink(String shareCode);

  Future<FriendProfile> resolveFriendProfileLink(String shareCode);

  Future<List<FriendConnection>> sendFriendRequestToProfile({
    required String userId,
    required String shareCode,
  });

  Future<List<FriendConnection>> acceptFriendRequest({
    required String userId,
    required String relationshipId,
  });

  Future<List<FriendConnection>> rejectFriendRequest({
    required String userId,
    required String relationshipId,
  });

  Future<List<FriendConnection>> cancelFriendRequest({
    required String userId,
    required String relationshipId,
  });

  Future<List<FriendConnection>> removeFriend({
    required String userId,
    required String friendUserId,
  });

  Future<List<DrinkDefinition>> loadDefaultCatalog();

  Future<List<DrinkDefinition>> loadCustomDrinks(String userId);

  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    String? imagePath,
  });

  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  });

  Future<List<DrinkEntry>> loadEntries(String userId);

  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    double? locationLatitude,
    double? locationLongitude,
    String? locationAddress,
    DateTime? consumedAt,
    String? importSource,
    String? importSourceId,
  });

  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  });

  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  });

  Future<UserSettings> loadSettings(String userId);

  Future<UserSettings> saveSettings(String userId, UserSettings settings);
}
