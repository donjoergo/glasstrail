import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_routes.dart';
import 'package:glasstrail/src/drink_icon_assets.dart';
import 'package:glasstrail/src/models.dart';

import 'support/test_harness.dart';

const _transparentPngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRSEAAAAASUVORK5CYII=';

Future<void> _openStatisticsSection(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byKey(const Key('statistics-tab-bar')),
    matching: find.text(label, skipOffstage: false),
  );
  await tester.ensureVisible(tab.first);
  await tester.tap(tab.first);
  await tester.pumpAndSettle();
}

Image _drinkImage(WidgetTester tester, Key key) {
  return tester.widget<Image>(
    find.descendant(of: find.byKey(key), matching: find.byType(Image)).first,
  );
}

Icon _drinkFallbackIcon(WidgetTester tester, Key key) {
  return tester.widget<Icon>(
    find.descendant(of: find.byKey(key), matching: find.byType(Icon)).first,
  );
}

BoxDecoration _drinkDecoration(WidgetTester tester, Key key) {
  return tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byKey(key),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration
      as BoxDecoration;
}

void main() {
  test('ships one PNG icon and accent color per default drink', () {
    final expectedAssets = <String>{
      for (final drink in buildDefaultDrinkCatalog())
        'assets/drink_icons/${drink.id}.png',
    };
    final actualAssets = Directory('assets/drink_icons')
        .listSync()
        .whereType<File>()
        .map((file) => file.path.replaceAll('\\', '/'))
        .toSet();

    expect(actualAssets, expectedAssets);
    for (final drink in buildDefaultDrinkCatalog()) {
      expect(
        builtInDrinkIconAssetPath(drink.id),
        'assets/drink_icons/${drink.id}.png',
      );
      expect(builtInDrinkAccentColorHex(drink.id), isNotNull);
    }
    expect(builtInDrinkIconAssetPath('future-drink-id'), isNull);
    expect(builtInDrinkAccentColorHex('future-drink-id'), isNull);
  });

  testWidgets('renders a built-in recent drink with its asset icon', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'recent-assets@example.com',
      password: 'password123',
      displayName: 'Recent Assets',
    );
    final pils = controller.availableDrinks.firstWhere(
      (drink) => drink.id == 'beer-pils',
    );
    await controller.addDrinkEntry(drink: pils, volumeMl: pils.volumeMl);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-add-drink-fab')));
    await tester.pumpAndSettle();

    const iconKey = Key('recent-drink-icon-beer-pils');
    final image = _drinkImage(tester, iconKey);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/drink_icons/beer-pils.png',
    );
    expect(
      find.descendant(of: find.byKey(iconKey), matching: find.byType(Icon)),
      findsNothing,
    );
    final decoration = _drinkDecoration(tester, iconKey);
    expect(
      decoration.color,
      drinkAccentColorFromHex(builtInDrinkAccentColorHex('beer-pils')),
    );
    expect(decoration.shape, BoxShape.circle);
  });

  testWidgets('renders a custom drink image in the bar custom drinks list', (
    tester,
  ) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'custom-icon@example.com',
      password: 'password123',
      displayName: 'Custom Icon',
    );
    await controller.saveCustomDrink(
      name: 'Mate Deluxe',
      category: DrinkCategory.nonAlcoholic,
      volumeMl: 500,
      imagePath: _transparentPngDataUrl,
    );
    final customDrink = controller.customDrinks.singleWhere(
      (drink) => drink.name == 'Mate Deluxe',
    );

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.barCustom,
      ),
    );
    await tester.pumpAndSettle();

    final iconKey = Key('bar-custom-drink-icon-${customDrink.id}');
    final image = _drinkImage(tester, iconKey);
    expect(image.image, isA<MemoryImage>());
    expect(
      find.descendant(of: find.byKey(iconKey), matching: find.byType(Icon)),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byKey(iconKey), matching: find.byType(ClipOval)),
      findsOneWidget,
    );
    expect(_drinkDecoration(tester, iconKey).shape, BoxShape.circle);
  });

  testWidgets(
    'falls back to the category icon when an entry drink definition is missing',
    (tester) async {
      final controller = await buildTestController();
      await controller.signUp(
        email: 'missing-definition@example.com',
        password: 'password123',
        displayName: 'Missing Definition',
      );
      await controller.saveCustomDrink(
        name: 'Lost Colada',
        category: DrinkCategory.cocktails,
        volumeMl: 250,
        imagePath: _transparentPngDataUrl,
      );
      final customDrink = controller.customDrinks.singleWhere(
        (drink) => drink.name == 'Lost Colada',
      );
      await controller.addDrinkEntry(
        drink: customDrink,
        volumeMl: customDrink.volumeMl,
      );
      final entry = controller.entries.single;
      await controller.deleteCustomDrink(customDrink);

      await tester.pumpWidget(
        GlassTrailApp(
          controller: controller,
          photoService: const TestPhotoService(),
          initialRoute: AppRoutes.statistics,
        ),
      );
      await tester.pumpAndSettle();

      await _openStatisticsSection(tester, 'History');

      final iconKey = Key('statistics-history-entry-icon-${entry.id}');
      final icon = _drinkFallbackIcon(tester, iconKey);
      expect(icon.icon, DrinkCategory.cocktails.icon);
      expect(
        find.descendant(of: find.byKey(iconKey), matching: find.byType(Image)),
        findsNothing,
      );
      final expectedColor = drinkCategoryAccentColor(
        DrinkCategory.cocktails,
        Theme.of(tester.element(find.byKey(iconKey))),
      );
      final decoration = _drinkDecoration(tester, iconKey);
      expect(decoration.color, expectedColor);
      expect(decoration.shape, BoxShape.circle);
    },
  );

  testWidgets('falls back to the category icon in map pins', (tester) async {
    final controller = await buildTestController();
    await controller.signUp(
      email: 'missing-map-definition@example.com',
      password: 'password123',
      displayName: 'Missing Map Definition',
    );
    await controller.saveCustomDrink(
      name: 'Map Mystery',
      category: DrinkCategory.longdrinks,
      volumeMl: 250,
    );
    final customDrink = controller.customDrinks.singleWhere(
      (drink) => drink.name == 'Map Mystery',
    );
    await controller.addDrinkEntry(
      drink: customDrink,
      volumeMl: customDrink.volumeMl,
      locationLatitude: 48.1372,
      locationLongitude: 11.5756,
    );
    final entry = controller.entries.single;
    await controller.deleteCustomDrink(customDrink);

    await tester.pumpWidget(
      GlassTrailApp(
        controller: controller,
        photoService: const TestPhotoService(),
        initialRoute: AppRoutes.statistics,
      ),
    );
    await tester.pumpAndSettle();

    await _openStatisticsSection(tester, 'Map');

    final iconKey = Key('statistics-map-marker-icon-${entry.id}');
    final icon = _drinkFallbackIcon(tester, iconKey);
    expect(icon.icon, DrinkCategory.longdrinks.icon);
    expect(
      find.descendant(of: find.byKey(iconKey), matching: find.byType(Image)),
      findsNothing,
    );
    final expectedColor = drinkCategoryAccentColor(
      DrinkCategory.longdrinks,
      Theme.of(tester.element(find.byKey(iconKey))),
    );
    expect(_drinkDecoration(tester, iconKey).color, expectedColor);
  });
}
