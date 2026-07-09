import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/src/achievements/catalog_models.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/location_service.dart';

import 'support/test_harness.dart';

const _homeLocation = EntryLocationData(latitude: 52.5200, longitude: 13.4050);
const _workLocation = EntryLocationData(latitude: 48.1351, longitude: 11.5820);

Future<void> _openPlacesScreen(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('profile-places-button')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(const Key('profile-places-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('setting a new Home archives the old Home', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'places@example.com',
      password: 'password123',
      displayName: 'Places Example',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        locationService: const TestLocationService(result: _homeLocation),
      ),
    );
    await tester.pumpAndSettle();
    await _openPlacesScreen(tester);

    await tester.tap(find.byIcon(Icons.my_location_rounded).first);
    await tester.pumpAndSettle();

    expect(controller.savedPlaces, hasLength(1));
    expect(controller.savedPlaces.single.isActive, isTrue);

    // Replace it: requires confirmation.
    await tester.tap(find.byIcon(Icons.my_location_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Replace'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(controller.savedPlaces, hasLength(2));
    expect(controller.savedPlaces.where((p) => p.isActive), hasLength(1));
    expect(controller.savedPlaces.where((p) => !p.isActive), hasLength(1));
  });

  testWidgets('cancelling the replace confirmation keeps the existing active place', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'places-cancel@example.com',
      password: 'password123',
      displayName: 'Places Cancel',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        locationService: const TestLocationService(result: _homeLocation),
      ),
    );
    await tester.pumpAndSettle();
    await _openPlacesScreen(tester);

    await tester.tap(find.byIcon(Icons.my_location_rounded).first);
    await tester.pumpAndSettle();
    expect(controller.savedPlaces, hasLength(1));

    // Attempt to replace, then cancel the confirmation dialog.
    await tester.tap(find.byIcon(Icons.my_location_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Replace'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(controller.savedPlaces, hasLength(1));
    expect(controller.savedPlaces.single.isActive, isTrue);
  });

  testWidgets('deleting a saved place removes it from the list', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'delete-place@example.com',
      password: 'password123',
      displayName: 'Delete Place',
    );
    await controller.setSavedPlace(
      placeType: SavedPlaceType.home,
      latitude: _homeLocation.latitude,
      longitude: _homeLocation.longitude,
    );
    await controller.setSavedPlace(
      placeType: SavedPlaceType.home,
      latitude: _workLocation.latitude,
      longitude: _workLocation.longitude,
    );
    expect(controller.savedPlaces, hasLength(2));

    await tester.pumpWidget(
      GlassTrailApp(controller: controller, photoService: const TestPhotoService()),
    );
    await tester.pumpAndSettle();
    await _openPlacesScreen(tester);

    expect(find.text('Previous places'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(controller.savedPlaces, hasLength(1));
  });
}
