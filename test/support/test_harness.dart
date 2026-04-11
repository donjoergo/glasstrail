import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/location_service.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

class TestPhotoService extends PhotoService {
  const TestPhotoService({this.path = '/tmp/mock-image.png'});

  final String? path;

  @override
  Future<String?> pickImage({
    required ImageUploadPreset preset,
    PhotoPickSource source = PhotoPickSource.gallery,
  }) async => path;
}

class RecordingPhotoService extends PhotoService {
  RecordingPhotoService({this.path = '/tmp/mock-image.png'});

  final String? path;
  final List<ImageUploadPreset> pickedPresets = <ImageUploadPreset>[];
  final List<PhotoPickSource> pickedSources = <PhotoPickSource>[];

  @override
  Future<String?> pickImage({
    required ImageUploadPreset preset,
    PhotoPickSource source = PhotoPickSource.gallery,
  }) async {
    pickedPresets.add(preset);
    pickedSources.add(source);
    return path;
  }
}

class TestLocationService extends LocationService {
  const TestLocationService({
    this.result,
    this.accuracyStatus = LocationAccuracyStatus.unknown,
    this.error,
    this.openSettingsResult = true,
  });

  final EntryLocationData? result;
  final LocationAccuracyStatus accuracyStatus;
  final Object? error;
  final bool openSettingsResult;

  @override
  Future<LocationFetchResult> fetchCurrentLocation({
    required String localeCode,
  }) async {
    if (error != null) {
      throw error!;
    }
    return LocationFetchResult(
      location: result,
      accuracyStatus: accuracyStatus,
    );
  }

  @override
  Future<bool> openAppSettings() async => openSettingsResult;
}

class RecordingLocationService extends LocationService {
  RecordingLocationService({
    this.result,
    this.accuracyStatus = LocationAccuracyStatus.unknown,
    this.openSettingsResult = true,
  });

  final EntryLocationData? result;
  final LocationAccuracyStatus accuracyStatus;
  final bool openSettingsResult;
  int openAppSettingsCalls = 0;
  int fetchCalls = 0;

  @override
  Future<LocationFetchResult> fetchCurrentLocation({
    required String localeCode,
  }) async {
    fetchCalls++;
    return LocationFetchResult(
      location: result,
      accuracyStatus: accuracyStatus,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return openSettingsResult;
  }
}

Future<AppController> buildTestController({
  Map<String, Object> initialValues = const <String, Object>{},
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(initialValues);
  final preferences = await SharedPreferences.getInstance();
  final repository = LocalAppRepository(preferences);
  return AppController.bootstrapWithRepository(repository);
}

Future<GlassTrailApp> buildTestApp({
  Map<String, Object> initialValues = const <String, Object>{},
  String? initialRoute,
  LocationService locationService = const TestLocationService(),
}) async {
  final controller = await buildTestController(initialValues: initialValues);
  return GlassTrailApp(
    controller: controller,
    photoService: const TestPhotoService(),
    locationService: locationService,
    initialRoute: initialRoute,
  );
}

Future<BlockingLocalAppRepository> buildBlockingLocalRepository({
  required AppBusyAction blockedAction,
  Map<String, Object> initialValues = const <String, Object>{},
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(initialValues);
  final preferences = await SharedPreferences.getInstance();
  return BlockingLocalAppRepository(preferences, blockedAction: blockedAction);
}

class BlockingLocalAppRepository extends LocalAppRepository {
  BlockingLocalAppRepository(
    super.preferences, {
    required this.blockedAction,
    Completer<void>? blocker,
  }) : blocker = blocker ?? Completer<void>();

  final AppBusyAction blockedAction;
  final Completer<void> blocker;

  void unblock() {
    if (!blocker.isCompleted) {
      blocker.complete();
    }
  }

  Future<T> _runBlocked<T>(
    AppBusyAction action,
    Future<T> Function() operation,
  ) async {
    if (blockedAction == action) {
      await blocker.future;
    }
    return operation();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _runBlocked(
      AppBusyAction.signIn,
      () => super.signIn(email: email, password: password),
    );
  }

  @override
  Future<void> signOut() {
    return _runBlocked(AppBusyAction.signOut, () => super.signOut());
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthday,
    String? profileImagePath,
  }) {
    return _runBlocked(
      AppBusyAction.signUp,
      () => super.signUp(
        email: email,
        password: password,
        displayName: displayName,
        birthday: birthday,
        profileImagePath: profileImagePath,
      ),
    );
  }

  @override
  Future<AppUser> updateProfile(AppUser user) {
    return _runBlocked(
      AppBusyAction.updateProfile,
      () => super.updateProfile(user),
    );
  }

  @override
  Future<DrinkDefinition> saveCustomDrink({
    required String userId,
    String? drinkId,
    required String name,
    required DrinkCategory category,
    double? volumeMl,
    String? imagePath,
  }) {
    return _runBlocked(
      AppBusyAction.saveCustomDrink,
      () => super.saveCustomDrink(
        userId: userId,
        drinkId: drinkId,
        name: name,
        category: category,
        volumeMl: volumeMl,
        imagePath: imagePath,
      ),
    );
  }

  @override
  Future<void> deleteCustomDrink({
    required String userId,
    required DrinkDefinition drink,
  }) {
    return _runBlocked(
      AppBusyAction.deleteCustomDrink,
      () => super.deleteCustomDrink(userId: userId, drink: drink),
    );
  }

  @override
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
  }) {
    return _runBlocked(
      AppBusyAction.addDrinkEntry,
      () => super.addDrinkEntry(
        user: user,
        drink: drink,
        volumeMl: volumeMl,
        comment: comment,
        imagePath: imagePath,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        locationAddress: locationAddress,
        consumedAt: consumedAt,
      ),
    );
  }

  @override
  Future<UserSettings> saveSettings(String userId, UserSettings settings) {
    return _runBlocked(
      AppBusyAction.updateSettings,
      () => super.saveSettings(userId, settings),
    );
  }

  @override
  Future<DrinkEntry> updateDrinkEntry({
    required AppUser user,
    required DrinkEntry entry,
    String? comment,
    String? imagePath,
  }) {
    return _runBlocked(
      AppBusyAction.updateDrinkEntry,
      () => super.updateDrinkEntry(
        user: user,
        entry: entry,
        comment: comment,
        imagePath: imagePath,
      ),
    );
  }

  @override
  Future<void> deleteDrinkEntry({
    required String userId,
    required DrinkEntry entry,
  }) {
    return _runBlocked(
      AppBusyAction.deleteDrinkEntry,
      () => super.deleteDrinkEntry(userId: userId, entry: entry),
    );
  }
}
