import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/app_scope.dart';
import 'package:glasstrail/src/import_file_service.dart';
import 'package:glasstrail/src/location_service.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';
import 'package:glasstrail/src/screens/add_drink_screen.dart';
import 'package:glasstrail/src/screens/feed_screen.dart';
import 'package:glasstrail/src/screens/home_shell.dart';
import 'package:glasstrail/src/screens/profile_screen.dart';
import 'package:glasstrail/src/screens/statistics_screen.dart';

import 'support/test_harness.dart';

const _transparentPngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRSEAAAAASUVORK5CYII=';
const _lastAcknowledgedReleaseKey = 'glasstrail.last_acknowledged_release';
const _currentReleaseId = '1.0.0+1';
const _changelogUrl =
    'https://github.com/donjoergo/glasstrail/blob/main/CHANGELOG.md';

AppLocalizations _l10n(String languageCode) =>
    lookupAppLocalizations(Locale(languageCode));

Color? _foregroundColor(ButtonStyle? style) =>
    style?.foregroundColor?.resolve(<WidgetState>{});

Color? _backgroundColor(ButtonStyle? style) =>
    style?.backgroundColor?.resolve(<WidgetState>{});

BorderSide? _borderSide(ButtonStyle? style) =>
    style?.side?.resolve(<WidgetState>{});

Future<({AppController controller, BlockingLocalAppRepository repository})>
_buildBlockedHarness(AppBusyAction action) async {
  final repository = await buildBlockingLocalRepository(blockedAction: action);
  final controller = await AppController.bootstrapWithRepository(repository);
  return (controller: controller, repository: repository);
}

Future<void> _openProfileTab(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

Future<void> _openStatisticsTab(
  WidgetTester tester, {
  String label = 'Statistics',
}) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _openBarCustomDrinksTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bar-custom-tab')));
  await tester.pumpAndSettle();
}

Future<void> _openStatisticsSection(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byKey(const Key('statistics-tab-bar')),
    matching: find.text(label, skipOffstage: false),
  );
  await tester.ensureVisible(tab.first);
  await tester.tap(tab.first);
  await tester.pumpAndSettle();
}

String? _homeShellRouteName(WidgetTester tester) {
  return ModalRoute.of(tester.element(find.byType(HomeShell)))?.settings.name;
}

String _rememberedRoute(WidgetTester tester) {
  return AppScope.routeMemoryOf(
    tester.element(find.byType(HomeShell)),
  ).lastRoute;
}

Finder _profileScrollable() => find.descendant(
  of: find.byType(ProfileScreen),
  matching: find.byType(Scrollable),
);

Future<void> _scrollProfileTargetIntoView(
  WidgetTester tester,
  Finder target,
) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: _profileScrollable(),
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
}

Future<void> _scrollBarTargetIntoView(
  WidgetTester tester,
  Finder target,
) async {
  final customList = find.byKey(const Key('bar-custom-list-view'));
  final sortList = find.byKey(const Key('bar-sort-list-view'));
  final activeScrollable = customList.evaluate().isNotEmpty
      ? find.descendant(of: customList, matching: find.byType(Scrollable)).first
      : find.descendant(of: sortList, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target, 200, scrollable: activeScrollable);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
}

class _RecordingUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> launchedUrls = <String>[];
  final List<LaunchOptions> launchOptions = <LaunchOptions>[];
  bool launchResult = true;
  Object? launchError;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (launchError != null) {
      throw launchError!;
    }
    launchedUrls.add(url);
    launchOptions.add(options);
    return launchResult;
  }
}

Future<void> _tapPhotoAction(
  WidgetTester tester,
  Finder button, {
  PhotoPickSource source = PhotoPickSource.gallery,
}) async {
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();

  final sourceOption = switch (source) {
    PhotoPickSource.camera => find.byKey(
      const Key('photo-source-camera-option'),
    ),
    PhotoPickSource.gallery => find.byKey(
      const Key('photo-source-gallery-option'),
    ),
  };
  if (sourceOption.evaluate().isEmpty) {
    return;
  }

  await tester.tap(sourceOption);
  await tester.pumpAndSettle();
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

Finder _statisticsMapMarker(String entryId) {
  return find.byKey(Key('statistics-map-marker-$entryId'));
}

Finder _statisticsMapMarkers() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('statistics-map-marker-') &&
        !key.value.startsWith('statistics-map-marker-icon-');
  });
}

Finder _appBarRichText(String text) {
  return find.descendant(
    of: find.byType(AppBar),
    matching: find.byWidgetPredicate((widget) {
      if (widget is! RichText) {
        return false;
      }
      return widget.text.toPlainText() == text;
    }),
  );
}

Future<List<DrinkEntry>> _seedGalleryEntries(
  AppController controller, {
  required int count,
  bool withImages = true,
}) async {
  final drinks = controller.availableDrinks.take(count).toList(growable: false);
  for (var index = 0; index < drinks.length; index++) {
    final drink = drinks[index];
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Gallery note ${index + 1}',
      imagePath: withImages ? _transparentPngDataUrl : null,
      locationLatitude: 52.5 + index,
      locationLongitude: 13.4 + index,
      locationAddress: 'Gallery Place ${index + 1}',
    );
  }

  return controller.entries
      .where((entry) => entry.imagePath?.trim().isNotEmpty ?? false)
      .toList(growable: false);
}

void main() {
  late UrlLauncherPlatform initialUrlLauncherPlatform;
  late _RecordingUrlLauncherPlatform urlLauncherPlatform;

  setUpAll(() {
    initialUrlLauncherPlatform = UrlLauncherPlatform.instance;
  });

  tearDownAll(() {
    UrlLauncherPlatform.instance = initialUrlLauncherPlatform;
  });

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Glass Trail',
      packageName: 'dev.glasstrail.glasstrail',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    urlLauncherPlatform = _RecordingUrlLauncherPlatform();
    UrlLauncherPlatform.instance = urlLauncherPlatform;
    debugForceUpdateNotice = false;
  });

  testWidgets('opens profile editing on a separate screen', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'alice@example.com',
      password: 'password123',
      displayName: 'Alice Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('edit-profile-display-name-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('edit-profile-save-button')), findsOneWidget);
  });

  testWidgets('shows a spinner while saving the profile', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.updateProfile);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'profile-busy@example.com',
      password: 'password123',
      displayName: 'Profile Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-profile-display-name-field')),
      'Profile Busy Updated',
    );
    await tester.tap(find.byKey(const Key('edit-profile-save-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('edit-profile-save-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('edit-profile-display-name-field')),
          )
          .enabled,
      isFalse,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.text('Profile Busy Updated'), findsOneWidget);
  });

  testWidgets('stretches edit-profile action buttons to the right edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-actions@example.com',
      password: 'password123',
      displayName: 'Profile Actions',
      birthday: DateTime(1990, 7, 13),
      profileImagePath: '/tmp/mock-image.png',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('edit-profile-save-button')),
    );
    await tester.pumpAndSettle();

    final saveRect = tester.getRect(
      find.byKey(const Key('edit-profile-save-button')),
    );
    final changePhotoRect = tester.getRect(
      find.byKey(const Key('edit-profile-change-photo-button')),
    );
    final removePhotoRect = tester.getRect(
      find.byKey(const Key('edit-profile-remove-photo-button')),
    );
    final birthdayRect = tester.getRect(
      find.byKey(const Key('edit-profile-birthday-button')),
    );
    final removeBirthdayRect = tester.getRect(
      find.byKey(const Key('edit-profile-remove-birthday-button')),
    );

    expect(
      changePhotoRect.right,
      moreOrLessEquals(saveRect.right, epsilon: 0.01),
    );
    expect(
      removePhotoRect.right,
      moreOrLessEquals(saveRect.right, epsilon: 0.01),
    );
    expect(
      removeBirthdayRect.right,
      moreOrLessEquals(saveRect.right, epsilon: 0.01),
    );
    expect(removeBirthdayRect.width, greaterThan(birthdayRect.width));
    expect(
      birthdayRect.top,
      moreOrLessEquals(removeBirthdayRect.top, epsilon: 0.01),
    );

    final theme = Theme.of(
      tester.element(find.byKey(const Key('edit-profile-save-button'))),
    );
    final removePhotoButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('edit-profile-remove-photo-button')),
    );
    final removeBirthdayButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('edit-profile-remove-birthday-button')),
    );

    expect(_foregroundColor(removePhotoButton.style), theme.colorScheme.error);
    expect(
      _borderSide(removePhotoButton.style),
      BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.72)),
    );
    expect(
      _foregroundColor(removeBirthdayButton.style),
      theme.colorScheme.error,
    );
    expect(
      _borderSide(removeBirthdayButton.style),
      BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.72)),
    );
  });

  testWidgets('uses the profile preset when changing the profile photo', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-photo-preset@example.com',
      password: 'password123',
      displayName: 'Profile Photo Preset',
    );
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.tap(find.byKey(const Key('profile-edit-button')));
    await tester.pumpAndSettle();
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.profile,
    ]);
  });

  testWidgets('spreads the statistics tabs evenly across the bar', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'statistics-tabbar@example.com',
      password: 'password123',
      displayName: 'Statistics Tabbar',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    final tabBarFinder = find.byKey(const Key('statistics-tab-bar'));
    final l10n = AppLocalizations.of(tester.element(tabBarFinder));
    final tabBarRect = tester.getRect(tabBarFinder);
    final labels = <String>[
      l10n.statisticsOverview,
      l10n.statisticsMap,
      l10n.statisticsGallery,
      l10n.history,
    ];
    final labelRects = labels
        .map(
          (label) => tester.getRect(
            find.descendant(
              of: tabBarFinder,
              matching: find.text(label, skipOffstage: false),
            ),
          ),
        )
        .toList(growable: false);
    final expectedCenters = List<double>.generate(
      labels.length,
      (index) =>
          tabBarRect.left +
          tabBarRect.width * ((index * 2 + 1) / (labels.length * 2)),
      growable: false,
    );

    for (var index = 0; index < labelRects.length; index++) {
      expect(
        labelRects[index].center.dx,
        moreOrLessEquals(expectedCenters[index], epsilon: 24),
      );
    }
  });

  testWidgets('updates the route when selecting statistics tabs', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'statistics-route-tabs@example.com',
      password: 'password123',
      displayName: 'Statistics Route Tabs',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsSection(tester, 'Map');
    expect(_homeShellRouteName(tester), AppRoutes.statistics);
    expect(_rememberedRoute(tester), AppRoutes.statisticsMap);
    expect(find.byKey(const Key('statistics-map-empty-state')), findsOneWidget);

    await _openStatisticsSection(tester, 'History');
    expect(_homeShellRouteName(tester), AppRoutes.statistics);
    expect(_rememberedRoute(tester), AppRoutes.statisticsHistory);
    expect(
      find.byKey(const Key('statistics-history-empty-state')),
      findsOneWidget,
    );
  });

  testWidgets(
    'keeps the old route until the statistics tab animation completes',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'statistics-route-animation@example.com',
        password: 'password123',
        displayName: 'Statistics Route Animation',
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.statistics,
        ),
      );
      await tester.pumpAndSettle();

      final mapTab = find.descendant(
        of: find.byKey(const Key('statistics-tab-bar')),
        matching: find.text('Map', skipOffstage: false),
      );
      await tester.tap(mapTab.first);
      await tester.pump();

      expect(_rememberedRoute(tester), AppRoutes.statistics);

      await tester.pumpAndSettle();

      expect(_rememberedRoute(tester), AppRoutes.statisticsMap);
    },
  );

  testWidgets('updates the route when swiping statistics tabs', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'statistics-route-swipe@example.com',
      password: 'password123',
      displayName: 'Statistics Route Swipe',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TabBarView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(_homeShellRouteName(tester), AppRoutes.statistics);
    expect(_rememberedRoute(tester), AppRoutes.statisticsMap);
    expect(find.byKey(const Key('statistics-map-empty-state')), findsOneWidget);
  });

  testWidgets('shows a field-local spinner while saving settings', (
    tester,
  ) async {
    final harness = await _buildBlockedHarness(AppBusyAction.updateSettings);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'settings-busy@example.com',
      password: 'password123',
      displayName: 'Settings Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await tester.ensureVisible(
      find.byKey(const Key('language-segmented-control')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('language-segmented-control')),
        matching: find.text('German'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('language-settings-loading')), findsOneWidget);
    expect(find.byKey(const Key('theme-settings-loading')), findsNothing);

    repository.unblock();
    await tester.pumpAndSettle();

    expect(controller.settings.localeCode, 'de');
    expect(find.byKey(const Key('language-settings-loading')), findsNothing);
  });

  testWidgets('shows the about section with version and GitHub link', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'about@example.com',
      password: 'password123',
      displayName: 'About Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await _scrollProfileTargetIntoView(
      tester,
      find.byKey(const Key('profile-about-section')),
    );

    expect(find.byKey(const Key('profile-about-section')), findsOneWidget);
    expect(find.text('Glass Trail V1.0.0'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(
      find.text(
        'created with ❤️, ☕ and 🍺 by Jörg Dorlach',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('profile-about-version-button')));
    await tester.pumpAndSettle();

    expect(urlLauncherPlatform.launchedUrls, <String>[
      'https://github.com/donjoergo/glasstrail/blob/main/CHANGELOG.md',
    ]);
    expect(
      urlLauncherPlatform.launchOptions.single.mode,
      PreferredLaunchMode.inAppBrowserView,
    );

    await tester.tap(find.byKey(const Key('profile-about-github-button')));
    await tester.pumpAndSettle();

    expect(urlLauncherPlatform.launchedUrls, <String>[
      'https://github.com/donjoergo/glasstrail/blob/main/CHANGELOG.md',
      'https://github.com/donjoergo/GlassTrail',
    ]);
    expect(
      urlLauncherPlatform.launchOptions.last.mode,
      PreferredLaunchMode.externalApplication,
    );
  });

  testWidgets('imports a BeerWithMe export from the profile screen', (
    tester,
  ) async {
    final l10n = _l10n('en');
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-import@example.com',
      password: 'password123',
      displayName: 'Profile Import Example',
    );

    final importFileService = TestImportFileService(
      file: SelectedImportFile(
        name: 'history.json',
        contents: jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'id': 1,
            'timestamp': '2022-06-06T22:55:15.000+02:00',
            'glassType': 'WineRose',
            'address': 'no_address',
          },
        ]),
      ),
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        importFileService: importFileService,
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await _scrollProfileTargetIntoView(
      tester,
      find.byKey(const Key('profile-import-section')),
    );

    await tester.tap(find.byKey(const Key('profile-import-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('beer-with-me-import-confirm-dialog')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('beer-with-me-import-confirm-dialog')),
        matching: find.widgetWithText(
          FilledButton,
          l10n.beerWithMeImportAction,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('beer-with-me-import-result-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('beer-with-me-import-summary-imported')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('beer-with-me-import-summary-skipped')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('beer-with-me-import-summary-errors')),
      findsNothing,
    );
    expect(find.text(l10n.beerWithMeImportResultImported(1)), findsOneWidget);
    expect(find.text(l10n.beerWithMeImportResultSkipped(0)), findsNothing);
    expect(find.text(l10n.beerWithMeImportResultErrors(0)), findsNothing);
    expect(
      find.byKey(const Key('beer-with-me-import-summary-total')),
      findsOneWidget,
    );
    expect(controller.entries.single.importSourceId, '1');
    expect(controller.entries.single.locationAddress, isNull);
  });

  testWidgets('shows BeerWithMe import progress while the import is running', (
    tester,
  ) async {
    final l10n = _l10n('en');
    final harness = await _buildBlockedHarness(AppBusyAction.addDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'profile-import-progress@example.com',
      password: 'password123',
      displayName: 'Profile Import Progress Example',
    );

    final importFileService = TestImportFileService(
      file: SelectedImportFile(
        name: 'history.json',
        contents: jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'id': 2,
            'timestamp': '2022-06-06T22:55:15.000+02:00',
            'glassType': 'WineRose',
            'address': 'no_address',
          },
        ]),
      ),
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        importFileService: importFileService,
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    await _scrollProfileTargetIntoView(
      tester,
      find.byKey(const Key('profile-import-section')),
    );

    await tester.tap(find.byKey(const Key('profile-import-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('beer-with-me-import-confirm-dialog')),
        matching: find.widgetWithText(
          FilledButton,
          l10n.beerWithMeImportAction,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('profile-import-progress-indicator')),
      findsOneWidget,
    );
    expect(find.text(l10n.beerWithMeImportProgress(0, 1)), findsOneWidget);
    expect(
      find.text(l10n.beerWithMeImportProgressDetails(0, 0, 0)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-import-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, l10n.beerWithMeImportCancelAction),
      findsOneWidget,
    );
    final cancelButton = tester.widget<FilledButton>(
      find.byKey(const Key('profile-import-cancel-button')),
    );
    final profileTheme = Theme.of(
      tester.element(find.byKey(const Key('profile-import-section'))),
    );
    expect(
      _backgroundColor(cancelButton.style),
      profileTheme.colorScheme.errorContainer,
    );
    expect(
      _foregroundColor(cancelButton.style),
      profileTheme.colorScheme.onErrorContainer,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('beer-with-me-import-result-dialog')),
      findsOneWidget,
    );
  });

  testWidgets(
    'can cancel a running BeerWithMe import from the profile screen',
    (tester) async {
      final l10n = _l10n('en');
      final harness = await _buildBlockedHarness(AppBusyAction.addDrinkEntry);
      final controller = harness.controller;
      final repository = harness.repository;
      await controller.signUp(
        email: 'profile-import-cancel@example.com',
        password: 'password123',
        displayName: 'Profile Import Cancel Example',
      );

      final importFileService = TestImportFileService(
        file: SelectedImportFile(
          name: 'history.json',
          contents: jsonEncode(<Map<String, Object?>>[
            <String, Object?>{
              'id': 3,
              'timestamp': '2022-06-06T22:55:15.000+02:00',
              'glassType': 'WineRose',
              'address': 'no_address',
            },
            <String, Object?>{
              'id': 4,
              'timestamp': '2022-06-06T23:10:00.000+02:00',
              'glassType': 'Beer',
              'address': 'no_address',
            },
          ]),
        ),
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          importFileService: importFileService,
        ),
      );
      await tester.pumpAndSettle();

      await _openProfileTab(tester);
      await _scrollProfileTargetIntoView(
        tester,
        find.byKey(const Key('profile-import-section')),
      );

      await tester.tap(find.byKey(const Key('profile-import-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('beer-with-me-import-confirm-dialog')),
          matching: find.widgetWithText(
            FilledButton,
            l10n.beerWithMeImportAction,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('profile-import-cancel-button')));
      await tester.pump();

      expect(controller.isBeerWithMeImportCancellationRequested, isTrue);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('profile-import-cancel-button')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text(l10n.beerWithMeImportCancelling), findsOneWidget);

      repository.unblock();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('beer-with-me-import-result-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('beer-with-me-import-status-banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('beer-with-me-import-summary-imported')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('beer-with-me-import-summary-skipped')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('beer-with-me-import-summary-errors')),
        findsNothing,
      );
      expect(
        find.text(l10n.beerWithMeImportResultCancelled(1, 2)),
        findsOneWidget,
      );
      expect(
        controller.entries.map((entry) => entry.importSourceId),
        contains('3'),
      );
      expect(
        controller.entries.map((entry) => entry.importSourceId),
        isNot(contains('4')),
      );
    },
  );

  testWidgets('does not show backend information on the profile screen', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'profile-backend@example.com',
      password: 'password123',
      displayName: 'Profile Backend Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);

    expect(find.text(_l10n('en').backend), findsNothing);
  });

  testWidgets('moves the add-drink fab for left-handed mode', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'fab@example.com',
      password: 'password123',
      displayName: 'Fab Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    final rightRect = tester.getRect(
      find.byKey(const Key('global-add-drink-fab')),
    );
    expect(
      rightRect.center.dx,
      greaterThan(tester.view.physicalSize.width / 2),
    );

    await controller.updateSettings(
      controller.settings.copyWith(handedness: AppHandedness.left),
    );
    await tester.pumpAndSettle();

    final leftRect = tester.getRect(
      find.byKey(const Key('global-add-drink-fab')),
    );
    expect(leftRect.center.dx, lessThan(tester.view.physicalSize.width / 2));
  });

  testWidgets('shows a spinner while confirming a new drink entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final harness = await _buildBlockedHarness(AppBusyAction.addDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'add-busy@example.com',
      password: 'password123',
      displayName: 'Add Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pils'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('confirm-drink-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('drink-comment-field')))
          .enabled,
      isFalse,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(controller.entries, hasLength(1));
  });

  testWidgets('shows and saves add-drink volumes in selected units', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'oz@example.com',
      password: 'password123',
      displayName: 'Oz Example',
    );
    await controller.updateSettings(
      controller.settings.copyWith(unit: AppUnit.oz),
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    expect(find.text('330 ml'), findsNothing);

    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();

    expect(find.text('11.2 oz'), findsWidgets);

    final pilsTile = find.widgetWithText(ListTile, 'Pils');
    await tester.ensureVisible(pilsTile);
    await tester.tap(pilsTile);
    await tester.pumpAndSettle();

    expect(find.text('Volume (oz)'), findsOneWidget);

    final volumeField = tester.widget<TextFormField>(
      find.byKey(const Key('drink-volume-field')),
    );
    expect(volumeField.controller?.text, '11.2');

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pumpAndSettle();

    expect(controller.entries, hasLength(1));
    expect(controller.entries.single.volumeMl, closeTo(330, 0.2));
  });

  testWidgets('shows detected location on the add-drink screen and saves it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'location-save@example.com',
      password: 'password123',
      displayName: 'Location Save',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        locationService: const TestLocationService(
          result: EntryLocationData(
            latitude: 52.52,
            longitude: 13.405,
            address: 'Alexanderplatz 1, 10178 Berlin',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pils'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drink-location-toggle')), findsOneWidget);
    expect(find.text('Alexanderplatz 1, 10178 Berlin'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pumpAndSettle();

    final entry = controller.entries.single;
    expect(entry.locationLatitude, 52.52);
    expect(entry.locationLongitude, 13.405);
    expect(entry.locationAddress, 'Alexanderplatz 1, 10178 Berlin');
  });

  testWidgets('can disable location for a single drink entry', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'location-disabled@example.com',
      password: 'password123',
      displayName: 'Location Disabled',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        locationService: const TestLocationService(
          result: EntryLocationData(
            latitude: 52.52,
            longitude: 13.405,
            address: 'Alexanderplatz 1, 10178 Berlin',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pils'));
    await tester.pumpAndSettle();
    final addDrinkListView = find
        .descendant(
          of: find.byType(AddDrinkScreen),
          matching: find.byType(ListView),
        )
        .first;
    await tester.drag(addDrinkListView, const Offset(0, -500));
    await tester.pumpAndSettle();
    final locationToggle = find.byKey(const Key('drink-location-toggle'));
    await tester.ensureVisible(locationToggle);
    await tester.tap(locationToggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drink-location-value')), findsOneWidget);
    expect(find.text('Location disabled for this entry.'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-drink-button')));
    await tester.pumpAndSettle();

    final entry = controller.entries.single;
    expect(entry.locationLatitude, isNull);
    expect(entry.locationLongitude, isNull);
    expect(entry.locationAddress, isNull);
  });

  testWidgets('shows a precise-location hint and opens app settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'location-approximate@example.com',
      password: 'password123',
      displayName: 'Location Approximate',
    );
    final locationService = RecordingLocationService(
      result: const EntryLocationData(
        latitude: 52.52,
        longitude: 13.405,
        address: 'Alexanderplatz 1, 10178 Berlin',
      ),
      accuracyStatus: LocationAccuracyStatus.reduced,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        locationService: locationService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pils'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('drink-location-approximate-warning')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('drink-location-open-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(locationService.openAppSettingsCalls, 1);
  });

  testWidgets(
    'shows localized global drink names on the add-drink screen during search',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'de@example.com',
        password: 'password123',
        displayName: 'Deutsch Beispiel',
      );
      await controller.updateSettings(
        controller.settings.copyWith(localeCode: 'de'),
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('global-add-drink-fab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('drink-search-field')),
        'rot',
      );
      await tester.pumpAndSettle();

      expect(find.text('Rotwein'), findsOneWidget);
      expect(find.text('Red Wine'), findsNothing);

      await tester.tap(find.byKey(const Key('drink-search-clear-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('drink-search-field')),
        'champ',
      );
      await tester.pumpAndSettle();

      expect(find.text('Champagner'), findsOneWidget);
      expect(find.text('Champagne'), findsNothing);
    },
  );

  testWidgets('localizes drink names in feed and statistics', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'entry-locale@example.com',
      password: 'password123',
      displayName: 'Eintrag Beispiel',
    );
    controller.takeFlashMessage(_l10n('de'));

    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    final redWine = controller.availableDrinks.firstWhere(
      (drink) => drink.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: redWine, volumeMl: redWine.volumeMl);
    controller.takeFlashMessage(_l10n('de'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rotwein'), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);

    await _openStatisticsTab(tester, label: 'Statistiken');
    await _openStatisticsSection(tester, 'Historie');

    expect(find.text('Rotwein'), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);
  });

  testWidgets('shows entry addresses in feed and statistics history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'entry-address@example.com',
      password: 'password123',
      displayName: 'Entry Address Example',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      locationLatitude: 52.52,
      locationLongitude: 13.405,
      locationAddress: 'Alexanderplatz 1, 10178 Berlin',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alexanderplatz 1, 10178 Berlin'), findsOneWidget);

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Alexanderplatz 1, 10178 Berlin'), findsOneWidget);
  });

  testWidgets('updates renamed custom drinks in feed and statistics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'custom-rename@example.com',
      password: 'password123',
      displayName: 'Custom Rename Example',
    );

    await controller.saveCustomDrink(
      name: 'Office Brew',
      category: DrinkCategory.nonAlcoholic,
      volumeMl: 300,
    );
    final customDrink = controller.customDrinks.single;
    await controller.addDrinkEntry(
      drink: customDrink,
      volumeMl: customDrink.volumeMl,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office Brew'), findsOneWidget);

    await controller.saveCustomDrink(
      drinkId: customDrink.id,
      name: 'Desk Coffee',
      category: customDrink.category,
      volumeMl: customDrink.volumeMl,
    );
    await tester.pumpAndSettle();

    expect(find.text('Desk Coffee'), findsOneWidget);
    expect(find.text('Office Brew'), findsNothing);

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Desk Coffee'), findsOneWidget);
    expect(find.text('Office Brew'), findsNothing);
  });

  testWidgets('shows custom drink management on bar instead of profile', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-custom-screen@example.com',
      password: 'password123',
      displayName: 'Bar Custom Screen',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    final customSection = find.byKey(const Key('bar-custom-drinks-section'));
    await _scrollBarTargetIntoView(tester, customSection);
    expect(customSection, findsOneWidget);
    expect(
      find.byKey(const Key('bar-add-custom-drink-button')),
      findsOneWidget,
    );

    await _openProfileTab(tester);
    expect(
      find.byKey(const Key('profile-add-custom-drink-button')),
      findsNothing,
    );
  });

  testWidgets('updates the route when selecting the bar custom tab', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-route-tabs@example.com',
      password: 'password123',
      displayName: 'Bar Route Tabs',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);

    expect(_homeShellRouteName(tester), AppRoutes.bar);
    expect(_rememberedRoute(tester), AppRoutes.barCustom);
    expect(find.byKey(const Key('bar-custom-drinks-section')), findsOneWidget);
  });

  testWidgets('keeps the old route until the bar tab animation completes', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-route-animation@example.com',
      password: 'password123',
      displayName: 'Bar Route Animation',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bar-custom-tab')));
    await tester.pump();

    expect(_rememberedRoute(tester), AppRoutes.bar);

    await tester.pumpAndSettle();

    expect(_rememberedRoute(tester), AppRoutes.barCustom);
  });

  testWidgets('updates the route when swiping bar tabs', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-route-swipe@example.com',
      password: 'password123',
      displayName: 'Bar Route Swipe',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TabBarView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(_homeShellRouteName(tester), AppRoutes.bar);
    expect(_rememberedRoute(tester), AppRoutes.barCustom);
    expect(find.byKey(const Key('bar-custom-drinks-section')), findsOneWidget);
  });

  testWidgets('shows an empty state when no custom drinks exist', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(1000, 1200));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-custom-empty@example.com',
      password: 'password123',
      displayName: 'Bar Custom Empty',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);

    final emptyState = find.byKey(const Key('bar-custom-empty-state'));
    final customSection = find.byKey(const Key('bar-custom-drinks-section'));

    expect(emptyState, findsOneWidget);
    expect(find.text('No custom drinks yet'), findsOneWidget);
    expect(
      find.text('Create your first custom drink and it will appear here.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('bar-add-custom-drink-button')),
      findsOneWidget,
    );

    final emptyStateRect = tester.getRect(emptyState);
    final customSectionRect = tester.getRect(customSection);
    expect(emptyStateRect.width, lessThan(400));
    expect(emptyStateRect.center.dx, closeTo(customSectionRect.center.dx, 0.1));
  });

  testWidgets('defaults new custom drinks to beer', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'custom-default-category@example.com',
      password: 'password123',
      displayName: 'Custom Default Category',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('bar-add-custom-drink-button'),
    );
    await _scrollBarTargetIntoView(tester, addCustomDrinkButton);
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Test Lager');
    await tester.tap(find.byKey(const Key('custom-drink-save-button')));
    await tester.pumpAndSettle();

    expect(controller.customDrinks, hasLength(1));
    expect(controller.customDrinks.single.category, DrinkCategory.beer);
  });

  testWidgets('creates alcohol-free custom beer from the beer-only switch', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'custom-alcohol-free-beer@example.com',
      password: 'password123',
      displayName: 'Custom Alcohol Free Beer',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('bar-add-custom-drink-button'),
    );
    await _scrollBarTargetIntoView(tester, addCustomDrinkButton);
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('custom-drink-alcohol-free-switch')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).first, 'Free Lager');
    await tester.tap(find.byKey(const Key('custom-drink-alcohol-free-switch')));
    await tester.tap(find.byKey(const Key('custom-drink-save-button')));
    await tester.pumpAndSettle();

    expect(controller.customDrinks.single.category, DrinkCategory.beer);
    expect(controller.customDrinks.single.isAlcoholFree, isTrue);
    expect(find.textContaining('Alcohol-free'), findsWidgets);
  });

  testWidgets('hides the alcohol-free switch for non-alcoholic custom drinks', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'custom-non-alcoholic@example.com',
      password: 'password123',
      displayName: 'Custom Non Alcoholic',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('bar-add-custom-drink-button'),
    );
    await _scrollBarTargetIntoView(tester, addCustomDrinkButton);
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'House Water');
    await tester.tap(find.byType(DropdownButtonFormField<DrinkCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Non-alcoholic').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('custom-drink-alcohol-free-switch')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('custom-drink-save-button')));
    await tester.pumpAndSettle();

    expect(controller.customDrinks.single.category, DrinkCategory.nonAlcoholic);
    expect(controller.customDrinks.single.isAlcoholFree, isTrue);
    expect(find.textContaining('Alcohol-free'), findsNothing);
  });

  testWidgets('shows a spinner while saving a custom drink', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.saveCustomDrink);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'custom-busy@example.com',
      password: 'password123',
      displayName: 'Custom Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('bar-add-custom-drink-button'),
    );
    await _scrollBarTargetIntoView(tester, addCustomDrinkButton);
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Night Cap');
    await tester.tap(find.byKey(const Key('custom-drink-save-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('custom-drink-save-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('custom-drink-cancel-button')),
          )
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.text('Night Cap'), findsOneWidget);
  });

  testWidgets(
    'deletes a custom drink from the edit dialog and keeps history visible',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'delete-custom-ui@example.com',
        password: 'password123',
        displayName: 'Delete Custom Ui',
      );

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
      );
      final customDrink = controller.customDrinks.single;
      await controller.addDrinkEntry(
        drink: customDrink,
        volumeMl: customDrink.volumeMl,
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.bar,
        ),
      );
      await tester.pumpAndSettle();

      await _openBarCustomDrinksTab(tester);
      await tester.tap(
        find.byKey(Key('bar-edit-custom-drink-${customDrink.id}')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('custom-drink-delete-button')),
        findsOneWidget,
      );
      final dialogTheme = Theme.of(
        tester.element(find.byKey(const Key('custom-drink-delete-button'))),
      );
      final deleteButton = tester.widget<TextButton>(
        find.byKey(const Key('custom-drink-delete-button')),
      );
      expect(
        _foregroundColor(deleteButton.style),
        dialogTheme.colorScheme.error,
      );

      await tester.tap(find.byKey(const Key('custom-drink-delete-button')));
      await tester.pumpAndSettle();
      final confirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('delete-custom-drink-confirm-button')),
      );
      expect(
        _backgroundColor(confirmButton.style),
        dialogTheme.colorScheme.error,
      );
      expect(
        _foregroundColor(confirmButton.style),
        dialogTheme.colorScheme.onError,
      );
      await tester.tap(
        find.byKey(const Key('delete-custom-drink-confirm-button')),
      );
      await tester.pumpAndSettle();

      expect(controller.customDrinks, isEmpty);
      expect(
        find.byKey(Key('bar-custom-drink-${customDrink.id}')),
        findsNothing,
      );
      expect(find.byKey(const Key('bar-custom-empty-state')), findsOneWidget);

      await _openStatisticsTab(tester);
      await _openStatisticsSection(tester, 'History');

      expect(find.text('Office Brew'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a bounded photo preview in the custom drink edit dialog without overflow',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'custom-photo-layout@example.com',
        password: 'password123',
        displayName: 'Custom Photo Layout',
      );

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
        imagePath: _transparentPngDataUrl,
      );
      final customDrink = controller.customDrinks.single;

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.bar,
        ),
      );
      await tester.pumpAndSettle();

      await _openBarCustomDrinksTab(tester);
      await tester.tap(
        find.byKey(Key('bar-edit-custom-drink-${customDrink.id}')),
      );
      await tester.pumpAndSettle();

      final preview = find.byKey(const Key('custom-drink-image-preview'));
      final changePhotoLabel = find.text('Change photo');
      final removePhotoLabel = find.text('Remove photo');
      final removePhotoButton = find.widgetWithText(
        OutlinedButton,
        'Remove photo',
      );
      final deleteButton = find.byKey(const Key('custom-drink-delete-button'));
      final cancelButton = find.byKey(const Key('custom-drink-cancel-button'));
      final saveButton = find.byKey(const Key('custom-drink-save-button'));
      expect(preview, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(preview).width, lessThanOrEqualTo(280));
      expect(changePhotoLabel, findsOneWidget);
      expect(removePhotoLabel, findsOneWidget);
      expect(
        (tester.getTopLeft(changePhotoLabel).dy -
                tester.getTopLeft(removePhotoLabel).dy)
            .abs(),
        lessThan(1),
      );
      expect(
        tester.getTopLeft(removePhotoLabel).dx,
        greaterThan(tester.getTopLeft(changePhotoLabel).dx),
      );
      expect(
        (tester.getRect(preview).top -
                tester.getRect(removePhotoButton).bottom) -
            (tester.getRect(deleteButton).top - tester.getRect(preview).bottom),
        closeTo(0, 1),
      );
      expect(
        (tester.getTopLeft(cancelButton).dy - tester.getTopLeft(saveButton).dy)
            .abs(),
        lessThan(1),
      );
      expect(
        tester.getTopLeft(deleteButton).dy,
        lessThan(tester.getTopLeft(cancelButton).dy),
      );
      expect(
        (tester.getTopRight(deleteButton).dx -
                tester.getTopRight(saveButton).dx)
            .abs(),
        lessThan(1),
      );
      expect(deleteButton, findsOneWidget);
      expect(saveButton, findsOneWidget);
    },
  );

  testWidgets(
    'keeps the custom drink delete action above the primary buttons on wider dialog layouts when needed',
    (tester) async {
      _setSurfaceSize(tester, const Size(1000, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'custom-photo-layout-web@example.com',
        password: 'password123',
        displayName: 'Custom Photo Layout Web',
      );

      await controller.saveCustomDrink(
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
        imagePath: _transparentPngDataUrl,
      );
      final customDrink = controller.customDrinks.single;

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.bar,
        ),
      );
      await tester.pumpAndSettle();

      await _openBarCustomDrinksTab(tester);
      await tester.tap(
        find.byKey(Key('bar-edit-custom-drink-${customDrink.id}')),
      );
      await tester.pumpAndSettle();

      final deleteButton = find.byKey(const Key('custom-drink-delete-button'));
      final cancelButton = find.byKey(const Key('custom-drink-cancel-button'));
      final saveButton = find.byKey(const Key('custom-drink-save-button'));
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(deleteButton).dy,
        lessThan(tester.getTopLeft(cancelButton).dy),
      );
      expect(
        (tester.getTopRight(deleteButton).dx -
                tester.getTopRight(saveButton).dx)
            .abs(),
        lessThan(1),
      );
    },
  );

  testWidgets('shows a spinner while deleting a custom drink', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.deleteCustomDrink);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'delete-custom-busy@example.com',
      password: 'password123',
      displayName: 'Delete Custom Busy',
    );

    await controller.saveCustomDrink(
      name: 'Night Cap',
      category: DrinkCategory.cocktails,
      volumeMl: 200,
    );
    final customDrink = controller.customDrinks.single;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    await tester.tap(
      find.byKey(Key('bar-edit-custom-drink-${customDrink.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('custom-drink-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('delete-custom-drink-confirm-button')),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('delete-custom-drink-confirm-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('delete-custom-drink-cancel-button')),
          )
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bar-custom-empty-state')), findsOneWidget);
  });

  testWidgets(
    'renders hidden global drinks in bar and removes them from add drink',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'bar-hide-global@example.com',
        password: 'password123',
        displayName: 'Bar Hide Global',
      );

      final pils = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-pils',
      );
      await controller.addDrinkEntry(drink: pils, volumeMl: pils.volumeMl);
      await controller.hideGlobalDrink(pils.id);

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.bar,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('bar-visible-global-drink-beer-pils'),
        ),
        findsNothing,
      );
      final hiddenDrinksToggle = find.text('Hidden drinks');
      await _scrollBarTargetIntoView(tester, hiddenDrinksToggle);
      await tester.tap(hiddenDrinksToggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bar-hidden-global-drink-beer-pils')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('global-add-drink-fab')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('recent-drink-icon-beer-pils')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('drink-category-title-beer')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Pils'), findsNothing);
      Navigator.of(tester.element(find.byType(AddDrinkScreen))).pop();
      await tester.pumpAndSettle();

      await controller.showGlobalDrink(pils.id);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('global-add-drink-fab')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('recent-drink-icon-beer-pils')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('drink-category-title-beer')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Pils'), findsOneWidget);
    },
  );

  testWidgets('hides and restores a whole global category from bar', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-hide-category@example.com',
      password: 'password123',
      displayName: 'Bar Hide Category',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    final hideCategoryButton = find.byKey(const Key('bar-hide-category-beer'));
    await _scrollBarTargetIntoView(tester, hideCategoryButton);
    await tester.tap(hideCategoryButton);
    await tester.pumpAndSettle();

    expect(controller.isGlobalCategoryHidden(DrinkCategory.beer), isTrue);
    expect(find.byKey(const Key('bar-show-category-beer')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('bar-visible-global-drink-beer-pils')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('drink-category-title-beer')), findsNothing);
    Navigator.of(tester.element(find.byType(AddDrinkScreen))).pop();
    await tester.pumpAndSettle();

    final showCategoryButton = find.byKey(const Key('bar-show-category-beer'));
    await _scrollBarTargetIntoView(tester, showCategoryButton);
    await tester.tap(showCategoryButton);
    await tester.pumpAndSettle();

    expect(controller.isGlobalCategoryHidden(DrinkCategory.beer), isFalse);
    expect(find.byKey(const Key('bar-hide-category-beer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('drink-category-title-beer')), findsOneWidget);
  });

  testWidgets(
    'reorders global drinks in bar and keeps that order in add drink',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'bar-reorder@example.com',
        password: 'password123',
        displayName: 'Bar Reorder',
      );
      final initialBeerIds = controller.availableDrinks
          .where(
            (drink) => !drink.isCustom && drink.category == DrinkCategory.beer,
          )
          .map((drink) => drink.id)
          .toList(growable: false);
      await controller.reorderGlobalDrinks(
        category: DrinkCategory.beer,
        orderedDrinkIds: <String>[
          initialBeerIds[1],
          initialBeerIds[0],
          ...initialBeerIds.skip(2),
        ],
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.bar,
        ),
      );
      await tester.pumpAndSettle();

      final hellesBarTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>('bar-visible-global-drink-beer-helles'),
        ),
      );
      final pilsBarTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>('bar-visible-global-drink-beer-pils'),
        ),
      );
      expect(hellesBarTop.dy, lessThan(pilsBarTop.dy));

      await tester.tap(find.byKey(const Key('global-add-drink-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink-category-title-beer')));
      await tester.pumpAndSettle();

      final hellesTileTop = tester.getTopLeft(
        find.widgetWithText(ListTile, 'Helles'),
      );
      final pilsTileTop = tester.getTopLeft(
        find.widgetWithText(ListTile, 'Pils'),
      );
      expect(hellesTileTop.dy, lessThan(pilsTileTop.dy));
    },
  );

  testWidgets(
    'reorders custom drinks together with global drinks in bar and keeps that order in add drink',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'bar-reorder-custom@example.com',
        password: 'password123',
        displayName: 'Bar Reorder Custom',
      );
      await controller.saveCustomDrink(
        name: 'Zulu Tonic',
        category: DrinkCategory.cocktails,
        volumeMl: 180,
      );
      final customDrink = controller.customDrinks.single;
      final mojito = controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'cocktails-mojito',
      );
      final cocktailIds = controller.availableDrinks
          .where((drink) => drink.category == DrinkCategory.cocktails)
          .map((drink) => drink.id)
          .toList(growable: false);
      await controller.reorderGlobalDrinks(
        category: DrinkCategory.cocktails,
        orderedDrinkIds: <String>[
          customDrink.id,
          mojito.id,
          ...cocktailIds.where((id) => id != customDrink.id && id != mojito.id),
        ],
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.bar,
        ),
      );
      await tester.pumpAndSettle();

      final customBarTop = tester.getTopLeft(
        find.byKey(
          ValueKey<String>('bar-visible-custom-drink-${customDrink.id}'),
        ),
      );
      final mojitoBarTop = tester.getTopLeft(
        find.byKey(
          const ValueKey<String>('bar-visible-global-drink-cocktails-mojito'),
        ),
      );
      expect(customBarTop.dy, lessThan(mojitoBarTop.dy));

      await tester.tap(find.byKey(const Key('global-add-drink-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drink-category-title-cocktails')));
      await tester.pumpAndSettle();

      final customTileTop = tester.getTopLeft(
        find.widgetWithText(ListTile, 'Zulu Tonic'),
      );
      final mojitoTileTop = tester.getTopLeft(
        find.widgetWithText(ListTile, 'Mojito'),
      );
      expect(customTileTop.dy, lessThan(mojitoTileTop.dy));
    },
  );

  testWidgets('uses the feed preset when picking an add-drink photo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'add-drink-photo-preset@example.com',
      password: 'password123',
      displayName: 'Add Drink Photo Preset',
    );
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drink-category-title-beer')));
    await tester.pumpAndSettle();
    final pilsTile = find.widgetWithText(ListTile, 'Pils');
    await tester.ensureVisible(pilsTile);
    await tester.tap(pilsTile);
    await tester.pumpAndSettle();
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.feed,
    ]);
  });

  testWidgets('uses the feed preset when picking a custom drink photo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'custom-drink-photo-preset@example.com',
      password: 'password123',
      displayName: 'Custom Drink Photo Preset',
    );
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: photoService,
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    await _openBarCustomDrinksTab(tester);
    final addCustomDrinkButton = find.byKey(
      const Key('bar-add-custom-drink-button'),
    );
    await _scrollBarTargetIntoView(tester, addCustomDrinkButton);
    await tester.tap(addCustomDrinkButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('custom-drink-save-button')), findsOneWidget);
    await _tapPhotoAction(tester, find.text('Pick photo'));

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.feed,
    ]);
  });

  testWidgets('shows the streak card in the feed without a details button', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'streak-card@example.com',
      password: 'password123',
      displayName: 'Streak Card Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-streak-card')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('feed-streak-current-value'))),
      isA<Text>().having((widget) => widget.data, 'data', '0 days'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('feed-streak-message'))),
      isA<Text>().having(
        (widget) => widget.data,
        'data',
        'Log a drink now to start your streak.',
      ),
    );
    expect(find.text('Details'), findsNothing);
    expect(find.byKey(const Key('feed-streak-day-1')), findsOneWidget);
    expect(find.byKey(const Key('feed-streak-day-7')), findsOneWidget);
  });

  testWidgets('does not show the changelog card on first launch', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'update-card-first-launch@example.com',
      password: 'password123',
      displayName: 'First Launch Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(find.byKey(const Key('feed-update-card')), findsNothing);
    expect(
      preferences.getString(_lastAcknowledgedReleaseKey),
      _currentReleaseId,
    );
  });

  testWidgets('shows the changelog card after an app update', (tester) async {
    final controller = await buildTestController(
      initialValues: <String, Object>{_lastAcknowledgedReleaseKey: '0.9.0+1'},
    );
    await controller.signUp(
      email: 'update-card@example.com',
      password: 'password123',
      displayName: 'Update Card Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('feed-update-card'));
    final streakCard = find.byKey(const Key('feed-streak-card'));

    expect(card, findsOneWidget);
    expect(find.text('App updated'), findsOneWidget);
    expect(find.byKey(const Key('feed-update-card-body')), findsOneWidget);
    expect(find.textContaining('1.0.0'), findsOneWidget);
    expect(
      tester.getTopLeft(card).dy,
      lessThan(tester.getTopLeft(streakCard).dy),
    );
  });

  testWidgets('shows the changelog card when forced by override', (
    tester,
  ) async {
    debugForceUpdateNotice = true;

    final controller = await buildTestController();
    await controller.signUp(
      email: 'update-card-forced@example.com',
      password: 'password123',
      displayName: 'Forced Update Card Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-update-card')), findsOneWidget);
    expect(find.textContaining('1.0.0'), findsOneWidget);
  });

  testWidgets('dismisses the changelog card until the next update', (
    tester,
  ) async {
    final controller = await buildTestController(
      initialValues: <String, Object>{_lastAcknowledgedReleaseKey: '0.9.0+1'},
    );
    await controller.signUp(
      email: 'update-card-dismiss@example.com',
      password: 'password123',
      displayName: 'Dismiss Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feed-update-card-close-button')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(find.byKey(const Key('feed-update-card')), findsNothing);
    expect(
      preferences.getString(_lastAcknowledgedReleaseKey),
      _currentReleaseId,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-update-card')), findsNothing);
  });

  testWidgets('opens the changelog and dismisses the card', (tester) async {
    final controller = await buildTestController(
      initialValues: <String, Object>{_lastAcknowledgedReleaseKey: '0.9.0+1'},
    );
    await controller.signUp(
      email: 'update-card-open@example.com',
      password: 'password123',
      displayName: 'Open Changelog Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('feed-update-card-whats-new-button')),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(urlLauncherPlatform.launchedUrls, <String>[_changelogUrl]);
    expect(
      urlLauncherPlatform.launchOptions.single.mode,
      PreferredLaunchMode.inAppBrowserView,
    );
    expect(
      preferences.getString(_lastAcknowledgedReleaseKey),
      _currentReleaseId,
    );
    expect(find.byKey(const Key('feed-update-card')), findsNothing);
  });

  testWidgets('keeps the changelog card visible when opening fails', (
    tester,
  ) async {
    final controller = await buildTestController(
      initialValues: <String, Object>{_lastAcknowledgedReleaseKey: '0.9.0+1'},
    );
    await controller.signUp(
      email: 'update-card-launch-error@example.com',
      password: 'password123',
      displayName: 'Launch Error Example',
    );
    controller.takeFlashMessage(_l10n('en'));
    urlLauncherPlatform.launchResult = false;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('feed-update-card-whats-new-button')),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(find.byKey(const Key('feed-update-card')), findsOneWidget);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(preferences.getString(_lastAcknowledgedReleaseKey), '0.9.0+1');
  });

  testWidgets('localizes the changelog card in German', (tester) async {
    final controller = await buildTestController(
      initialValues: <String, Object>{_lastAcknowledgedReleaseKey: '0.9.0+1'},
    );
    await controller.signUp(
      email: 'update-card-german@example.com',
      password: 'password123',
      displayName: 'German Example',
    );
    controller.takeFlashMessage(_l10n('en'));
    await controller.updateSettings(
      controller.settings.copyWith(localeCode: 'de'),
    );
    controller.takeFlashMessage(_l10n('de'));

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('App aktualisiert'), findsOneWidget);
    expect(
      find.textContaining('Glass Trail wurde gerade auf 1.0.0'),
      findsOneWidget,
    );
    expect(find.text('Schließen'), findsOneWidget);
    expect(find.text('Was gibt\'s Neues'), findsOneWidget);
  });

  testWidgets('refreshes the feed with pull to refresh', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'feed-refresh@example.com',
      password: 'password123',
      displayName: 'Feed Refresh Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('feed-streak-current-value'))),
      isA<Text>().having((widget) => widget.data, 'data', '0 days'),
    );
    expect(find.text('Pils'), findsNothing);

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: DateTime.now(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsNothing);

    await tester.drag(
      find.byKey(const Key('feed-list-view')),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('feed-streak-current-value'))),
      isA<Text>().having((widget) => widget.data, 'data', '1 day'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('feed-streak-message'))),
      isA<Text>().having(
        (widget) => widget.data,
        'data',
        'Very good! You started your streak today.',
      ),
    );
    expect(find.text('Pils'), findsOneWidget);
  });

  testWidgets('refreshes the statistics with pull to refresh', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-refresh@example.com',
      password: 'password123',
      displayName: 'Stats Refresh Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-weekly'))),
      isA<Text>().having((widget) => widget.data, 'data', '0'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-total'))),
      isA<Text>().having((widget) => widget.data, 'data', '0'),
    );

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: DateTime.now(),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('statistics-list-view')),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-weekly'))),
      isA<Text>().having((widget) => widget.data, 'data', '1'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-total'))),
      isA<Text>().having((widget) => widget.data, 'data', '1'),
    );
  });

  testWidgets('clears the add-drink search input and restores categories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'clear-search@example.com',
      password: 'password123',
      displayName: 'Clear Search Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('drink-search-field')), 'red');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drink-category-title-beer')), findsNothing);
    expect(find.text('Red Wine'), findsOneWidget);
    expect(find.byKey(const Key('drink-search-clear-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('drink-search-clear-button')));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextFormField>(
      find.byKey(const Key('drink-search-field')),
    );
    expect(searchField.controller?.text, isEmpty);
    expect(find.byKey(const Key('drink-category-title-beer')), findsOneWidget);
    expect(find.text('Red Wine'), findsNothing);
    expect(find.byKey(const Key('drink-search-clear-button')), findsNothing);
  });

  testWidgets(
    'keeps add-drink categories collapsed and closes them after selection',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'accordion@example.com',
        password: 'password123',
        displayName: 'Accordion Example',
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('global-add-drink-fab')));
      await tester.pumpAndSettle();

      expect(find.text('Pils'), findsNothing);
      expect(find.text('Red Wine'), findsNothing);

      await tester.tap(find.byKey(const Key('drink-category-title-beer')));
      await tester.pumpAndSettle();

      final pilsTile = find.widgetWithText(ListTile, 'Pils');
      expect(pilsTile, findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Red Wine'), findsNothing);

      await tester.tap(pilsTile);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Pils'), findsNothing);
      expect(find.byKey(const Key('drink-volume-field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('drink-category-title-wine')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Pils'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Red Wine'), findsOneWidget);
    },
  );

  testWidgets('shows icons for recent drinks and statistics cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'icons@example.com',
      password: 'password123',
      displayName: 'Icon Beispiel',
    );
    await controller.addDrinkEntry(
      drink: controller.availableDrinks.firstWhere(
        (drink) => drink.id == 'beer-pils',
      ),
      volumeMl: 330,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('recent-drink-icon-beer-pils')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pils'));
    await tester.pumpAndSettle();

    final recentDrinkChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Pils'),
    );
    expect(recentDrinkChip.selected, isTrue);
    expect(recentDrinkChip.showCheckmark, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);

    expect(find.byKey(const Key('stats-card-icon-weekly')), findsOneWidget);
    expect(find.byKey(const Key('stats-card-icon-monthly')), findsOneWidget);
    expect(find.byKey(const Key('stats-card-icon-yearly')), findsOneWidget);
    expect(find.byKey(const Key('stats-card-icon-total')), findsOneWidget);
    expect(
      find.byKey(const Key('stats-card-icon-current-streak')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-card-icon-best-streak')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('stats-category-chip-icon-beer')),
      findsOneWidget,
    );
  });

  testWidgets('shows the new global drink categories in the bar', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'bar-new-categories@example.com',
      password: 'password123',
      displayName: 'Bar New Categories',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.bar,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bar-category-card-sparklingWines')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'bar-visible-global-drink-sparklingWines-champagne',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('bar-category-card-longdrinks')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'bar-visible-global-drink-longdrinks-cuba-libre',
        ),
      ),
      findsOneWidget,
    );

    final shotsCard = find.byKey(const Key('bar-category-card-shots'));
    await _scrollBarTargetIntoView(tester, shotsCard);
    expect(shotsCard, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('bar-visible-global-drink-shots-jaegermeister'),
      ),
      findsOneWidget,
    );

    final appleWinesCard = find.byKey(
      const Key('bar-category-card-appleWines'),
    );
    await _scrollBarTargetIntoView(tester, appleWinesCard);
    expect(appleWinesCard, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('bar-visible-global-drink-appleWines-cider'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps totals and streaks in fixed overview rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-overview@example.com',
      password: 'password123',
      displayName: 'Stats Overview Example',
    );
    controller.takeFlashMessage(_l10n('en'));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );
    final today = DateTime.now();
    final bestStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 2));
    final bestEnd = bestStart.add(const Duration(days: 2));

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestStart,
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestStart.add(const Duration(days: 1)),
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestEnd,
    );
    await controller.refreshData();

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);

    expect(tester.takeException(), isNull);

    final weeklyIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-weekly')),
    );
    final monthlyIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-monthly')),
    );
    final yearlyIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-yearly')),
    );
    final totalIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-total')),
    );
    final currentStreakIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-current-streak')),
    );
    final bestStreakIconOffset = tester.getTopLeft(
      find.byKey(const Key('stats-card-icon-best-streak')),
    );

    expect(monthlyIconOffset.dy, closeTo(weeklyIconOffset.dy, 0.1));
    expect(yearlyIconOffset.dy, greaterThan(weeklyIconOffset.dy));
    expect(totalIconOffset.dy, closeTo(yearlyIconOffset.dy, 0.1));
    expect(currentStreakIconOffset.dy, greaterThan(yearlyIconOffset.dy));
    expect(bestStreakIconOffset.dy, closeTo(currentStreakIconOffset.dy, 0.1));
    expect(
      tester.widget<Text>(find.byKey(const Key('stats-card-value-total'))),
      isA<Text>().having((widget) => widget.data, 'data', '3'),
    );

    final expectedRange =
        '${DateFormat.MMMd(controller.settings.localeCode).format(bestStart)} - '
        '${DateFormat.MMMd(controller.settings.localeCode).format(bestEnd)}';
    expect(
      tester.widget<Text>(
        find.byKey(const Key('stats-card-best-streak-range')),
      ),
      isA<Text>().having((widget) => widget.data, 'data', expectedRange),
    );
  });

  testWidgets('shows the year for a best streak outside the current year', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-overview-last-year@example.com',
      password: 'password123',
      displayName: 'Stats Overview Last Year',
    );
    controller.takeFlashMessage(_l10n('en'));

    final preferences = await SharedPreferences.getInstance();
    final externalRepository = LocalAppRepository(preferences);
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );
    final today = DateTime.now();
    final bestStart = DateTime(today.year - 1, 12, 28);
    final bestEnd = bestStart.add(const Duration(days: 2));

    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestStart,
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestStart.add(const Duration(days: 1)),
    );
    await externalRepository.addDrinkEntry(
      user: controller.currentUser!,
      drink: drink,
      volumeMl: drink.volumeMl,
      consumedAt: bestEnd,
    );
    await controller.refreshData();

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);

    final expectedRange =
        '${DateFormat.yMMMd(controller.settings.localeCode).format(bestStart)} - '
        '${DateFormat.yMMMd(controller.settings.localeCode).format(bestEnd)}';
    expect(
      tester.widget<Text>(
        find.byKey(const Key('stats-card-best-streak-range')),
      ),
      isA<Text>().having((widget) => widget.data, 'data', expectedRange),
    );
  });

  testWidgets('shows a compact history view inside statistics', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-history-compact@example.com',
      password: 'password123',
      displayName: 'Stats History Compact',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Should stay out of compact stats history',
      imagePath: '/tmp/stats-history-image.png',
    );
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Should stay out of compact stats history'), findsNothing);
    expect(find.byKey(Key('feed-entry-image-$entryId')), findsNothing);
    expect(find.byKey(Key('feed-entry-actions-$entryId')), findsNothing);
  });

  testWidgets('shows an empty state for statistics history without entries', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-history-empty@example.com',
      password: 'password123',
      displayName: 'Stats History Empty',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(
      find.byKey(const Key('statistics-history-empty-state')),
      findsOneWidget,
    );
    expect(find.text('No history yet'), findsOneWidget);
    expect(
      find.text('Logged drinks will appear here as your personal history.'),
      findsOneWidget,
    );
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('filters the compact statistics history by category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-history-filter@example.com',
      password: 'password123',
      displayName: 'Stats History Filter',
    );

    final beer = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final wine = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );
    await controller.addDrinkEntry(drink: beer, volumeMl: beer.volumeMl);
    await controller.addDrinkEntry(drink: wine, volumeMl: wine.volumeMl);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'History');

    expect(find.text('Pils'), findsOneWidget);
    expect(find.text('Red Wine'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Wine (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsNothing);
    expect(find.text('Red Wine'), findsOneWidget);
  });

  testWidgets('shows the map empty state and gallery empty state', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-placeholders@example.com',
      password: 'password123',
      displayName: 'Stats Placeholders',
    );
    final drink = controller.availableDrinks.first;
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Entry without photo',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Map');

    expect(find.byKey(const Key('statistics-map-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('statistics-map-card')), findsNothing);
    expect(find.text('No drinks with location yet'), findsOneWidget);
    expect(
      find.text(
        'Enable location while logging drinks so they can appear here on the map.',
      ),
      findsOneWidget,
    );

    await _openStatisticsSection(tester, 'Gallery');

    expect(find.byKey(const Key('statistics-gallery-grid')), findsNothing);
    expect(find.text('No drink photos yet'), findsOneWidget);
    expect(
      find.text('Photos from logged drinks will appear here automatically.'),
      findsOneWidget,
    );
  });

  testWidgets('renders one statistics map marker per entry with coordinates', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(430, 1000));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-map-markers@example.com',
      password: 'password123',
      displayName: 'Stats Map Markers',
    );

    final beer = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final wine = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );
    final water = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );

    await controller.addDrinkEntry(
      drink: beer,
      volumeMl: beer.volumeMl,
      locationLatitude: 52.52,
      locationLongitude: 13.405,
      locationAddress: 'Alexanderplatz 1, 10178 Berlin',
    );
    final beerEntry = controller.entries.firstWhere(
      (entry) => entry.drinkId == beer.id,
    );
    await controller.addDrinkEntry(
      drink: wine,
      volumeMl: wine.volumeMl,
      locationLatitude: 48.1372,
      locationLongitude: 11.5756,
      locationAddress: 'Marienplatz 1, 80331 Munich',
    );
    final wineEntry = controller.entries.firstWhere(
      (entry) => entry.drinkId == wine.id,
    );
    await controller.addDrinkEntry(drink: water, volumeMl: water.volumeMl);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Map');

    expect(find.byKey(const Key('statistics-map-card')), findsOneWidget);
    expect(_statisticsMapMarkers(), findsNWidgets(2));
    expect(_statisticsMapMarker(beerEntry.id), findsOneWidget);
    expect(_statisticsMapMarker(wineEntry.id), findsOneWidget);
  });

  testWidgets('expands the statistics map card down to the navigation bar', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(430, 1000));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-map-height@example.com',
      password: 'password123',
      displayName: 'Stats Map Height',
    );

    final beer = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(
      drink: beer,
      volumeMl: beer.volumeMl,
      locationLatitude: 52.52,
      locationLongitude: 13.405,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Map');

    final mapBottom = tester
        .getBottomLeft(find.byKey(const Key('statistics-map-card')))
        .dy;
    final navigationTop = tester.getTopLeft(find.byType(NavigationBar)).dy;

    expect((mapBottom - navigationTop).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('stretches the statistics map card to the screen edges', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(430, 1000));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-map-width@example.com',
      password: 'password123',
      displayName: 'Stats Map Width',
    );

    final beer = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(
      drink: beer,
      volumeMl: beer.volumeMl,
      locationLatitude: 52.52,
      locationLongitude: 13.405,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Map');

    final mapLeft = tester
        .getTopLeft(find.byKey(const Key('statistics-map-card')))
        .dx;
    final mapRight = tester
        .getTopRight(find.byKey(const Key('statistics-map-card')))
        .dx;
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(mapLeft.abs(), lessThanOrEqualTo(1));
    expect((mapRight - screenWidth).abs(), lessThanOrEqualTo(1));
  });

  testWidgets(
    'does not show entries without coordinates as statistics markers',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'stats-map-filter@example.com',
        password: 'password123',
        displayName: 'Stats Map Filter',
      );

      final beer = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'beer-pils',
      );
      final wine = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'wine-red-wine',
      );

      await controller.addDrinkEntry(
        drink: beer,
        volumeMl: beer.volumeMl,
        locationLatitude: 52.52,
        locationLongitude: 13.405,
      );
      final mappedEntry = controller.entries.firstWhere(
        (entry) => entry.drinkId == beer.id,
      );
      await controller.addDrinkEntry(drink: wine, volumeMl: wine.volumeMl);
      final unmappedEntry = controller.entries.firstWhere(
        (entry) => entry.drinkId == wine.id,
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _openStatisticsTab(tester);
      await _openStatisticsSection(tester, 'Map');

      expect(_statisticsMapMarkers(), findsOneWidget);
      expect(_statisticsMapMarker(mappedEntry.id), findsOneWidget);
      expect(_statisticsMapMarker(unmappedEntry.id), findsNothing);
    },
  );

  testWidgets(
    'opens a statistics map sheet with localized name, time, volume and address',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'stats-map-sheet@example.com',
        password: 'password123',
        displayName: 'Stats Map Sheet',
      );
      await controller.updateSettings(
        controller.settings.copyWith(localeCode: 'de'),
      );

      final wine = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'wine-red-wine',
      );
      await controller.addDrinkEntry(
        drink: wine,
        volumeMl: 175,
        locationLatitude: 52.52,
        locationLongitude: 13.405,
        locationAddress: 'Alexanderplatz 1, 10178 Berlin',
      );
      final entry = controller.entries.firstWhere(
        (candidate) => candidate.drinkId == wine.id,
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _openStatisticsTab(tester, label: 'Statistiken');
      await _openStatisticsSection(tester, 'Karte');

      await tester.tap(_statisticsMapMarker(entry.id));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('statistics-map-sheet-${entry.id}')),
        findsOneWidget,
      );
      expect(
        find.text(controller.localizedEntryDrinkName(entry)),
        findsOneWidget,
      );
      expect(find.text('Wein'), findsOneWidget);
      expect(
        find.text(
          DateFormat.yMMMd(
            controller.settings.localeCode,
          ).add_Hm().format(entry.consumedAt),
        ),
        findsOneWidget,
      );
      expect(
        find.text(controller.settings.unit.formatVolume(entry.volumeMl)),
        findsOneWidget,
      );
      expect(find.text(entry.locationAddress!), findsOneWidget);
    },
  );

  testWidgets('shows statistics map comments and photos only when present', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(430, 1000));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-map-media@example.com',
      password: 'password123',
      displayName: 'Stats Map Media',
    );

    final beer = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    final wine = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'wine-red-wine',
    );

    await controller.addDrinkEntry(
      drink: beer,
      volumeMl: beer.volumeMl,
      comment: 'Map comment',
      imagePath: _transparentPngDataUrl,
      locationLatitude: 52.52,
      locationLongitude: 13.405,
    );
    final richEntry = controller.entries.firstWhere(
      (entry) => entry.drinkId == beer.id,
    );
    await controller.addDrinkEntry(
      drink: wine,
      volumeMl: wine.volumeMl,
      locationLatitude: 48.1372,
      locationLongitude: 11.5756,
    );
    final plainEntry = controller.entries.firstWhere(
      (entry) => entry.drinkId == wine.id,
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Map');

    await tester.tap(_statisticsMapMarker(richEntry.id));
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('statistics-map-sheet-comment-${richEntry.id}')),
      findsOneWidget,
    );
    expect(find.text('Map comment'), findsOneWidget);
    expect(
      find.byKey(Key('statistics-map-sheet-image-${richEntry.id}')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(_statisticsMapMarker(plainEntry.id));
    await tester.pumpAndSettle();

    expect(
      find.byKey(Key('statistics-map-sheet-comment-${plainEntry.id}')),
      findsNothing,
    );
    expect(
      find.byKey(Key('statistics-map-sheet-image-${plainEntry.id}')),
      findsNothing,
    );
  });

  test('resolves overlapping statistics map markers to zoom in', () {
    final resolution = resolveStatisticsMapMarkerTap(
      offsets: const <Offset>[
        Offset(120, 160),
        Offset(138, 176),
        Offset(260, 320),
      ],
      tappedIndex: 0,
      currentZoom: 14,
    );

    expect(resolution, StatisticsMapTapResolution.zoomIn);
    expect(
      statisticsMapOverlappingMarkerIndexes(
        offsets: const <Offset>[
          Offset(120, 160),
          Offset(138, 176),
          Offset(260, 320),
        ],
        tappedIndex: 0,
      ),
      <int>[0, 1],
    );
  });

  test('keeps isolated or fully resolved statistics map markers tappable', () {
    expect(
      resolveStatisticsMapMarkerTap(
        offsets: const <Offset>[Offset(120, 160), Offset(182, 230)],
        tappedIndex: 0,
        currentZoom: 14,
      ),
      StatisticsMapTapResolution.openSheet,
    );

    expect(
      resolveStatisticsMapMarkerTap(
        offsets: const <Offset>[Offset(120, 160), Offset(132, 170)],
        tappedIndex: 0,
        currentZoom: 18.5,
      ),
      StatisticsMapTapResolution.openSheet,
    );
  });

  test(
    'keeps standalone statistics map markers visible outside dense groups',
    () {
      expect(
        statisticsMapStandaloneMarkerIndexes(
          offsets: const <Offset>[
            Offset(60, 80),
            Offset(180, 220),
            Offset(214, 246),
          ],
        ),
        <int>[0],
      );
    },
  );

  test('groups dense statistics map markers into overlay clusters', () {
    expect(
      statisticsMapClusterGroups(
        offsets: const <Offset>[
          Offset(80, 100),
          Offset(108, 126),
          Offset(260, 320),
          Offset(288, 348),
          Offset(420, 180),
        ],
      ),
      const <List<int>>[
        <int>[0, 1],
        <int>[2, 3],
        <int>[4],
      ],
    );
  });

  testWidgets(
    'fans out statistics markers with the same rounded coordinates into separate positions',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'stats-map-fanout@example.com',
        password: 'password123',
        displayName: 'Stats Map Fanout',
      );

      final beer = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'beer-pils',
      );
      final wine = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'wine-red-wine',
      );

      await controller.addDrinkEntry(
        drink: beer,
        volumeMl: beer.volumeMl,
        locationLatitude: 52.52004,
        locationLongitude: 13.40496,
      );
      final firstEntry = controller.entries.firstWhere(
        (entry) => entry.drinkId == beer.id,
      );
      await controller.addDrinkEntry(
        drink: wine,
        volumeMl: wine.volumeMl,
        locationLatitude: 52.52003,
        locationLongitude: 13.40499,
      );
      final secondEntry = controller.entries.firstWhere(
        (entry) => entry.drinkId == wine.id,
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _openStatisticsTab(tester);
      await _openStatisticsSection(tester, 'Map');

      final firstCenter = tester.getCenter(_statisticsMapMarker(firstEntry.id));
      final secondCenter = tester.getCenter(
        _statisticsMapMarker(secondEntry.id),
      );

      expect(_statisticsMapMarkers(), findsNWidgets(2));
      expect((firstCenter - secondCenter).distance, greaterThan(1));
    },
  );

  testWidgets(
    'shows newest gallery photos first in three columns and opens the swipe viewer',
    (tester) async {
      _setSurfaceSize(tester, const Size(430, 1000));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'stats-gallery-phone@example.com',
        password: 'password123',
        displayName: 'Stats Gallery Phone',
      );
      final galleryEntries = await _seedGalleryEntries(controller, count: 4);

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
        ),
      );
      await tester.pumpAndSettle();

      await _openStatisticsTab(tester);
      await _openStatisticsSection(tester, 'Gallery');

      expect(find.byKey(const Key('statistics-gallery-grid')), findsOneWidget);

      final newestRect = tester.getRect(
        find.byKey(Key('statistics-gallery-tile-${galleryEntries[0].id}')),
      );
      final secondRect = tester.getRect(
        find.byKey(Key('statistics-gallery-tile-${galleryEntries[1].id}')),
      );
      final thirdRect = tester.getRect(
        find.byKey(Key('statistics-gallery-tile-${galleryEntries[2].id}')),
      );
      final fourthRect = tester.getRect(
        find.byKey(Key('statistics-gallery-tile-${galleryEntries[3].id}')),
      );

      expect((newestRect.top - secondRect.top).abs(), lessThan(0.1));
      expect((secondRect.top - thirdRect.top).abs(), lessThan(0.1));
      expect(newestRect.left, lessThan(secondRect.left));
      expect(secondRect.left, lessThan(thirdRect.left));
      expect(fourthRect.top, greaterThan(newestRect.top + 1));

      await tester.tap(
        find.byKey(Key('statistics-gallery-tile-${galleryEntries.first.id}')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('app-gallery-viewer-fullscreen')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('app-gallery-viewer-drink-name')),
            )
            .data,
        controller.localizedEntryDrinkName(galleryEntries.first),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app-gallery-viewer-comment')))
            .data,
        galleryEntries.first.comment,
      );
      expect(find.text(galleryEntries.first.locationAddress!), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('app-gallery-viewer-page-view')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 4'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('app-gallery-viewer-drink-name')),
            )
            .data,
        controller.localizedEntryDrinkName(galleryEntries[1]),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app-gallery-viewer-comment')))
            .data,
        galleryEntries[1].comment,
      );
      expect(find.text(galleryEntries[1].locationAddress!), findsOneWidget);
    },
  );

  testWidgets('uses four columns for gallery layouts on tablet widths', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(820, 1180));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-gallery-tablet@example.com',
      password: 'password123',
      displayName: 'Stats Gallery Tablet',
    );
    final galleryEntries = await _seedGalleryEntries(controller, count: 5);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsTab(tester);
    await _openStatisticsSection(tester, 'Gallery');

    final firstRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[0].id}')),
    );
    final secondRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[1].id}')),
    );
    final thirdRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[2].id}')),
    );
    final fourthRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[3].id}')),
    );
    final fifthRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[4].id}')),
    );

    expect((firstRect.top - secondRect.top).abs(), lessThan(0.1));
    expect((secondRect.top - thirdRect.top).abs(), lessThan(0.1));
    expect((thirdRect.top - fourthRect.top).abs(), lessThan(0.1));
    expect(fifthRect.top, greaterThan(firstRect.top + 1));
  });

  testWidgets('uses five columns for gallery layouts on wider screens', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(1200, 1366));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'stats-gallery-wide@example.com',
      password: 'password123',
      displayName: 'Stats Gallery Wide',
    );
    final galleryEntries = await _seedGalleryEntries(controller, count: 5);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsSection(tester, 'Gallery');

    final firstRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[0].id}')),
    );
    final secondRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[1].id}')),
    );
    final thirdRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[2].id}')),
    );
    final fourthRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[3].id}')),
    );
    final fifthRect = tester.getRect(
      find.byKey(Key('statistics-gallery-tile-${galleryEntries[4].id}')),
    );

    expect((firstRect.top - secondRect.top).abs(), lessThan(0.1));
    expect((secondRect.top - thirdRect.top).abs(), lessThan(0.1));
    expect((thirdRect.top - fourthRect.top).abs(), lessThan(0.1));
    expect((fourthRect.top - fifthRect.top).abs(), lessThan(0.1));
    expect(firstRect.left, lessThan(secondRect.left));
    expect(secondRect.left, lessThan(thirdRect.left));
    expect(thirdRect.left, lessThan(fourthRect.left));
    expect(fourthRect.left, lessThan(fifthRect.left));
  });

  testWidgets('uses a square rail surface on wider screens', (tester) async {
    _setSurfaceSize(tester, const Size(1200, 1366));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'wide-shell@example.com',
      password: 'password123',
      displayName: 'Wide Shell',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);

    final railContainer = tester.widget<Container>(
      find.byKey(const Key('home-shell-wide-rail-shell')),
    );
    expect(railContainer.decoration, isNull);
    expect(railContainer.color, isNotNull);
  });

  testWidgets(
    'renders dynamic size properties for the home shell app bar title',
    (tester) async {
      _setSurfaceSize(tester, const Size(1200, 1366));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'responsive-title@example.com',
        password: 'password123',
        displayName: 'Responsive Title',
      );

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.profile,
        ),
      );
      await tester.pumpAndSettle();

      final wideTitle = tester.widget<RichText>(_appBarRichText('Profile'));
      final wideStyle = (wideTitle.text as TextSpan).style;

      expect(wideStyle?.fontSize, 24);
      expect(wideStyle?.fontWeight, FontWeight.w800);

      _setSurfaceSize(tester, const Size(400, 800));
      await tester.pumpAndSettle();

      final narrowTitle = tester.widget<RichText>(_appBarRichText('Profile'));
      final narrowStyle = (narrowTitle.text as TextSpan).style;

      expect(narrowStyle?.fontSize, 20);
      expect(narrowStyle?.fontWeight, FontWeight.w800);
    },
  );

  testWidgets(
    'edits entry comment and image from history without exposing drink controls',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = await buildTestController();
      await controller.signUp(
        email: 'history-edit@example.com',
        password: 'password123',
        displayName: 'History Edit Example',
      );

      final drink = controller.availableDrinks.firstWhere(
        (candidate) => candidate.id == 'nonAlcoholic-water',
      );
      await controller.addDrinkEntry(
        drink: drink,
        volumeMl: drink.volumeMl,
        comment: 'Before edit',
        imagePath: '/tmp/before-edit.png',
      );
      final entryId = controller.entries.single.id;

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(path: '/tmp/updated-image.png'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('feed-entry-image-$entryId')), findsOneWidget);
      expect(find.text('before-edit.png'), findsNothing);

      await tester.tap(find.byKey(Key('feed-entry-actions-$entryId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('feed-entry-edit-$entryId')));
      await tester.pumpAndSettle();

      final commentField = tester.widget<TextFormField>(
        find.byKey(const Key('edit-entry-comment-field')),
      );
      expect(commentField.controller?.text, 'Before edit');
      expect(find.byKey(const Key('edit-entry-image-preview')), findsOneWidget);
      expect(find.text('before-edit.png'), findsNothing);
      expect(find.byKey(const Key('drink-search-field')), findsNothing);
      expect(find.byKey(const Key('drink-volume-field')), findsNothing);
      final editDialogTheme = Theme.of(
        tester.element(find.byKey(const Key('edit-entry-remove-photo-button'))),
      );
      final removePhotoButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('edit-entry-remove-photo-button')),
      );
      expect(
        _foregroundColor(removePhotoButton.style),
        editDialogTheme.colorScheme.error,
      );
      expect(
        _borderSide(removePhotoButton.style),
        BorderSide(
          color: editDialogTheme.colorScheme.error.withValues(alpha: 0.72),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('edit-entry-comment-field')),
        'After edit',
      );
      await tester.tap(find.byKey(const Key('edit-entry-remove-photo-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-entry-save-button')));
      await tester.pumpAndSettle();

      expect(controller.entries.single.comment, 'After edit');
      expect(controller.entries.single.imagePath, isNull);
      expect(find.text('After edit'), findsOneWidget);
      expect(find.text('Before edit'), findsNothing);
      expect(find.text('before-edit.png'), findsNothing);
    },
  );

  testWidgets('uses the feed preset when picking a history entry photo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'history-photo-preset@example.com',
      password: 'password123',
      displayName: 'History Photo Preset',
    );
    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    final entryId = controller.entries.single.id;
    final photoService = RecordingPhotoService(path: null);

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: photoService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('feed-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('feed-entry-edit-$entryId')));
    await tester.pumpAndSettle();
    await _tapPhotoAction(
      tester,
      find.byKey(const Key('edit-entry-pick-photo-button')),
    );

    expect(photoService.pickedPresets, <ImageUploadPreset>[
      ImageUploadPreset.feed,
    ]);
  });

  testWidgets('shows a spinner while saving an edited entry', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.updateDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'edit-busy@example.com',
      password: 'password123',
      displayName: 'Edit Busy',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'nonAlcoholic-water',
    );
    await controller.addDrinkEntry(
      drink: drink,
      volumeMl: drink.volumeMl,
      comment: 'Before edit',
    );
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('feed-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('feed-entry-edit-$entryId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-entry-comment-field')),
      'After edit',
    );
    await tester.tap(find.byKey(const Key('edit-entry-save-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('edit-entry-save-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('edit-entry-cancel-button')))
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.text('After edit'), findsOneWidget);
  });

  testWidgets('deletes a logged drink from history after confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await buildTestController();
    await controller.signUp(
      email: 'history-delete@example.com',
      password: 'password123',
      displayName: 'History Delete Example',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pils'), findsOneWidget);

    await tester.tap(find.byKey(Key('feed-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    final deleteMenuLabel = tester.widget<Text>(find.text('Delete entry').last);
    final menuTheme = Theme.of(
      tester.element(find.byKey(const Key('feed-streak-card'))),
    );
    expect(deleteMenuLabel.style?.color, menuTheme.colorScheme.error);
    await tester.tap(find.byKey(Key('feed-entry-delete-$entryId')));
    await tester.pumpAndSettle();
    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('delete-entry-confirm-button')),
    );
    expect(_backgroundColor(confirmButton.style), menuTheme.colorScheme.error);
    expect(
      _foregroundColor(confirmButton.style),
      menuTheme.colorScheme.onError,
    );
    await tester.tap(find.byKey(const Key('delete-entry-confirm-button')));
    await tester.pumpAndSettle();

    expect(controller.entries, isEmpty);
    expect(find.text('Pils'), findsNothing);
    expect(find.text('No drinks logged yet.'), findsOneWidget);

    final streakValue = tester.widget<Text>(
      find.byKey(const Key('feed-streak-current-value')),
    );
    expect(streakValue.data, '0 days');
  });

  testWidgets('shows a spinner while deleting an entry', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.deleteDrinkEntry);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'delete-busy@example.com',
      password: 'password123',
      displayName: 'Delete Busy',
    );

    final drink = controller.availableDrinks.firstWhere(
      (candidate) => candidate.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: drink, volumeMl: drink.volumeMl);
    final entryId = controller.entries.single.id;

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('feed-entry-actions-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('feed-entry-delete-$entryId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-entry-confirm-button')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('delete-entry-confirm-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('delete-entry-cancel-button')),
          )
          .onPressed,
      isNull,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(controller.entries, isEmpty);
  });

  testWidgets('shows a spinner while signing out', (tester) async {
    final harness = await _buildBlockedHarness(AppBusyAction.signOut);
    final controller = harness.controller;
    final repository = harness.repository;
    await controller.signUp(
      email: 'logout-busy@example.com',
      password: 'password123',
      displayName: 'Logout Busy',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openProfileTab(tester);
    final logoutButton = find.byKey(const Key('profile-logout-button'));
    await _scrollProfileTargetIntoView(tester, logoutButton);
    await tester.tap(logoutButton);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-logout-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    repository.unblock();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });
}
