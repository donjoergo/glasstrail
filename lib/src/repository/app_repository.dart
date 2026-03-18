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

  Future<List<DrinkEntry>> loadEntries(String userId);

  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    DateTime? consumedAt,
  });

  Future<UserSettings> loadSettings(String userId);

  Future<UserSettings> saveSettings(String userId, UserSettings settings);
}
