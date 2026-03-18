import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../birthday.dart';
import '../models.dart';
import 'app_repository.dart';

class SupabaseAppRepository implements AppRepository {
  SupabaseAppRepository(this._client, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  static const _mediaBucket = 'user-media';

  final SupabaseClient _client;
  final Uuid _uuid;

  @override
  String get backendLabel => 'Supabase';

  @override
  bool get usesRemoteBackend => true;

  @override
  Future<AppUser?> restoreSession() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return null;
    }
    return _authUserToUser(authUser);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'display_name': displayName.trim(),
          if (birthday != null) 'birthday': _toDateString(birthday),
          if (profileImagePath != null && profileImagePath.trim().isNotEmpty)
            'profile_image_path': profileImagePath.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AppException('Sign-up did not return a user.');
      }

      if (response.session == null) {
        throw const AppException(
          'Supabase sign-up succeeded, but email confirmation is enabled. Confirm the email first, then sign in.',
        );
      }

      return _ensureProfile(
        user,
        preferredDisplayName: displayName.trim(),
        preferredBirthday: birthday,
        preferredProfileImagePath: profileImagePath,
      );
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppException('The email or password is incorrect.');
      }
      return _ensureProfile(user);
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    try {
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: user.profileImagePath,
        folder: 'profiles',
      );

      await _client.auth.updateUser(
        UserAttributes(
          data: <String, dynamic>{
            'display_name': user.displayName,
            'birthday': user.birthday == null
                ? null
                : _toDateString(user.birthday!),
            'profile_image_path': finalImagePath,
          },
        ),
      );

      final row = await _client
          .from('profiles')
          .upsert(<String, dynamic>{
            'id': user.id,
            'email': user.email,
            'display_name': user.displayName,
            'birthday': user.birthday == null
                ? null
                : _toDateString(user.birthday!),
            'profile_image_path': finalImagePath,
          }, onConflict: 'id')
          .select()
          .single();

      return _profileToUser(
        Map<String, dynamic>.from(row),
        userId: user.id,
        email: user.email,
      );
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<DrinkDefinition>> loadDefaultCatalog() async {
    try {
      final rows = await _client
          .from('global_drinks')
          .select()
          .order('category_slug')
          .order('name_en');

      final drinks = (rows as List<dynamic>)
          .map(
            (row) =>
                _globalDrinkToDefinition(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      if (drinks.isEmpty) {
        return buildDefaultDrinkCatalog();
      }
      return drinks;
    } on PostgrestException {
      return buildDefaultDrinkCatalog();
    }
  }

  @override
  Future<List<DrinkDefinition>> loadCustomDrinks(String userId) async {
    try {
      final rows = await _client
          .from('user_drinks')
          .select()
          .eq('user_id', userId)
          .order('name');

      return (rows as List<dynamic>)
          .map(
            (row) =>
                _userDrinkToDefinition(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    String? imagePath,
  }) async {
    try {
      final id = drinkId ?? _uuid.v4();
      final finalImagePath = await _resolveMediaPath(
        userId: userId,
        imagePath: imagePath,
        folder: 'custom-drinks',
      );

      final row = await _client
          .from('user_drinks')
          .upsert(<String, dynamic>{
            'id': id,
            'user_id': userId,
            'name': name.trim(),
            'category_slug': category.storageValue,
            'volume_ml': volumeMl,
            'image_path': finalImagePath,
          }, onConflict: 'id')
          .select()
          .single();

      return _userDrinkToDefinition(Map<String, dynamic>.from(row));
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<List<DrinkEntry>> loadEntries(String userId) async {
    try {
      final rows = await _client
          .from('drink_entries')
          .select()
          .eq('user_id', userId)
          .order('consumed_at', ascending: false);

      return (rows as List<dynamic>)
          .map((row) => _entryFromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<DrinkEntry> addDrinkEntry({
    required AppUser user,
    required DrinkDefinition drink,
    double? volumeMl,
    String? comment,
    String? imagePath,
    DateTime? consumedAt,
  }) async {
    try {
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: imagePath,
        folder: 'entries',
      );

      final row = await _client
          .from('drink_entries')
          .insert(<String, dynamic>{
            'id': _uuid.v4(),
            'user_id': user.id,
            'source_type': drink.isCustom ? 'custom' : 'global',
            'source_drink_id': drink.id,
            'drink_name': drink.name,
            'category_slug': drink.category.storageValue,
            'volume_ml': volumeMl,
            'comment': comment?.trim().isEmpty ?? true ? null : comment?.trim(),
            'image_path': finalImagePath,
            'consumed_at': (consumedAt ?? DateTime.now())
                .toUtc()
                .toIso8601String(),
          })
          .select()
          .single();

      return _entryFromRow(Map<String, dynamic>.from(row));
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  }) async {
    try {
      final trimmedComment = comment?.trim();
      final trimmedImagePath = imagePath?.trim();
      final finalImagePath = await _resolveMediaPath(
        userId: user.id,
        imagePath: trimmedImagePath,
        folder: 'entries',
      );

      final row = await _client
          .from('drink_entries')
          .update(<String, dynamic>{
            'comment': trimmedComment == null || trimmedComment.isEmpty
                ? null
                : trimmedComment,
            'image_path': finalImagePath,
          })
          .eq('id', entry.id)
          .eq('user_id', user.id)
          .select()
          .maybeSingle();

      if (row == null) {
        throw const AppException('The drink entry could not be updated.');
      }

      if (entry.imagePath != finalImagePath) {
        await _deleteMediaPathIfOwned(entry.imagePath, user.id);
      }

      return _entryFromRow(Map<String, dynamic>.from(row));
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) async {
    try {
      final rows = await _client
          .from('drink_entries')
          .delete()
          .eq('id', entry.id)
          .eq('user_id', userId)
          .select('id');

      if ((rows as List<dynamic>).isEmpty) {
        throw const AppException('The drink entry could not be deleted.');
      }

      await _deleteMediaPathIfOwned(entry.imagePath, userId);
    } on StorageException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<UserSettings> loadSettings(String userId) async {
    try {
      final row = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        return UserSettings.defaults();
      }
      return UserSettings.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  @override
  Future<UserSettings> saveSettings(
    String userId,
    UserSettings settings,
  ) async {
    try {
      final row = await _client
          .from('user_settings')
          .upsert(<String, dynamic>{
            'user_id': userId,
            'theme_preference': settings.themePreference.storageValue,
            'locale_code': settings.localeCode,
            'unit': settings.unit.storageValue,
            'handedness': settings.handedness.storageValue,
          }, onConflict: 'user_id')
          .select()
          .single();

      return UserSettings.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw AppException(error.message);
    }
  }

  Future<AppUser> _ensureProfile(
    User authUser, {
    String? preferredDisplayName,
    DateTime? preferredBirthday,
    String? preferredProfileImagePath,
  }) async {
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing != null) {
      await _ensureSettingsRow(authUser.id);
      return _profileToUser(
        Map<String, dynamic>.from(existing),
        userId: authUser.id,
        email: authUser.email ?? '',
      );
    }

    final metadata = Map<String, dynamic>.from(
      authUser.userMetadata ?? const <String, dynamic>{},
    );
    final row = await _client
        .from('profiles')
        .insert(<String, dynamic>{
          'id': authUser.id,
          'email': authUser.email,
          'display_name':
              preferredDisplayName ??
              (metadata['display_name'] as String?) ??
              (metadata['nickname'] as String?) ??
              _fallbackDisplayName(authUser.email),
          'birthday': preferredBirthday == null
              ? metadata['birthday']
              : _toDateString(preferredBirthday),
          'profile_image_path':
              preferredProfileImagePath ??
              (metadata['profile_image_path'] as String?),
        })
        .select()
        .single();

    await _ensureSettingsRow(authUser.id);
    return _profileToUser(
      Map<String, dynamic>.from(row),
      userId: authUser.id,
      email: authUser.email ?? '',
    );
  }

  Future<void> _ensureSettingsRow(String userId) async {
    await _client
        .from('user_settings')
        .upsert(
          <String, dynamic>{
            'user_id': userId,
            'theme_preference': AppThemePreference.system.storageValue,
            'locale_code': 'en',
            'unit': AppUnit.ml.storageValue,
            'handedness': AppHandedness.right.storageValue,
          },
          onConflict: 'user_id',
          ignoreDuplicates: true,
        );
  }

  AppUser _profileToUser(
    Map<String, dynamic> row, {
    required String userId,
    required String email,
  }) {
    final birthdayRaw = row['birthday'];
    return AppUser(
      id: userId,
      email: (row['email'] as String?) ?? email,
      displayName:
          (row['display_name'] as String?) ??
          (row['nickname'] as String?) ??
          _fallbackDisplayName(email),
      profileImagePath: row['profile_image_path'] as String?,
      birthday: normalizeBirthdayOrNull(
        birthdayRaw == null ? null : DateTime.parse(birthdayRaw as String),
      ),
    );
  }

  AppUser _authUserToUser(User authUser) {
    final metadata = Map<String, dynamic>.from(
      authUser.userMetadata ?? const <String, dynamic>{},
    );
    final birthdayRaw = metadata['birthday'] as String?;

    return AppUser(
      id: authUser.id,
      email: authUser.email ?? '',
      displayName:
          (metadata['display_name'] as String?) ??
          (metadata['nickname'] as String?) ??
          _fallbackDisplayName(authUser.email),
      profileImagePath: metadata['profile_image_path'] as String?,
      birthday: normalizeBirthdayOrNull(
        birthdayRaw == null ? null : DateTime.parse(birthdayRaw),
      ),
    );
  }

  DrinkDefinition _globalDrinkToDefinition(Map<String, dynamic> row) {
    return DrinkDefinition(
      id: row['id'] as String,
      name: row['name_en'] as String,
      localizedNameDe: row['name_de'] as String?,
      category: DrinkCategoryX.fromStorage(row['category_slug'] as String),
      volumeMl: (row['default_volume_ml'] as num?)?.toDouble(),
    );
  }

  DrinkDefinition _userDrinkToDefinition(Map<String, dynamic> row) {
    return DrinkDefinition(
      id: row['id'] as String,
      name: row['name'] as String,
      category: DrinkCategoryX.fromStorage(row['category_slug'] as String),
      volumeMl: (row['volume_ml'] as num?)?.toDouble(),
      imagePath: row['image_path'] as String?,
      ownerUserId: row['user_id'] as String?,
    );
  }

  DrinkEntry _entryFromRow(Map<String, dynamic> row) {
    return DrinkEntry(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      drinkId: row['source_drink_id'] as String,
      drinkName: row['drink_name'] as String,
      category: DrinkCategoryX.fromStorage(row['category_slug'] as String),
      consumedAt: DateTime.parse(row['consumed_at'] as String).toLocal(),
      volumeMl: (row['volume_ml'] as num?)?.toDouble(),
      comment: row['comment'] as String?,
      imagePath: row['image_path'] as String?,
    );
  }

  Future<String?> _resolveMediaPath({
    required String userId,
    required String? imagePath,
    required String folder,
  }) async {
    final normalized = imagePath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (!_looksLikeLocalFile(normalized)) {
      return normalized;
    }

    final bytes = await XFile(normalized).readAsBytes();
    final fileName = normalized.split(RegExp(r'[\\/]')).last;
    final sanitized =
        '${DateTime.now().millisecondsSinceEpoch}-${fileName.replaceAll(' ', '-')}';
    final storagePath = '$userId/$folder/$sanitized';

    await _client.storage
        .from(_mediaBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _guessMimeType(fileName),
          ),
        );

    return storagePath;
  }

  bool _looksLikeLocalFile(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return false;
    }
    if (path.startsWith('/')) {
      return true;
    }
    if (path.contains(':\\')) {
      return true;
    }
    return path.startsWith('file://');
  }

  Future<void> _deleteMediaPathIfOwned(String? imagePath, String userId) async {
    final normalized = imagePath?.trim();
    if (!_isOwnedStoragePath(normalized, userId)) {
      return;
    }
    try {
      await _client.storage.from(_mediaBucket).remove(<String>[normalized!]);
    } on StorageException {
      // Best-effort cleanup; data changes should still succeed.
    }
  }

  bool _isOwnedStoragePath(String? imagePath, String userId) {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    if (_looksLikeLocalFile(imagePath)) {
      return false;
    }
    return imagePath.split('/').first == userId;
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _fallbackDisplayName(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) {
      return 'GlassTrail User';
    }
    return value.split('@').first;
  }

  String _toDateString(DateTime value) {
    final normalized = normalizeBirthday(value);
    return normalized.toIso8601String().split('T').first;
  }
}
