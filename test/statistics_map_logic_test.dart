import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/screens/statistics_screen.dart';

DrinkEntry _entry({
  required String id,
  required DrinkCategory category,
  required double latitude,
  required double longitude,
}) {
  return DrinkEntry(
    id: id,
    userId: 'user-1',
    drinkId: 'drink-$id',
    drinkName: 'Drink $id',
    category: category,
    consumedAt: DateTime.utc(2026, 1, 1),
    locationLatitude: latitude,
    locationLongitude: longitude,
  );
}

Map<String, Object?> _featureById(Map<String, Object> geoJson, String id) {
  final features = geoJson['features']! as List<Object?>;
  return features.cast<Map<String, Object?>>().singleWhere(
    (feature) => feature['id'] == id,
  );
}

List<double> _featureCoordinates(Map<String, Object?> feature) {
  final geometry = feature['geometry']! as Map<String, Object?>;
  return (geometry['coordinates']! as List<Object?>).cast<double>().toList(
    growable: false,
  );
}

Map<String, Object?> _featureProperties(Map<String, Object?> feature) {
  return feature['properties']! as Map<String, Object?>;
}

void main() {
  test('clustered source uses raw entry coordinates', () {
    final entries = <DrinkEntry>[
      _entry(
        id: 'beer-1',
        category: DrinkCategory.beer,
        latitude: 52.52004,
        longitude: 13.40496,
      ),
      _entry(
        id: 'wine-1',
        category: DrinkCategory.wine,
        latitude: 48.13743,
        longitude: 11.57549,
      ),
    ];

    final geoJson = statisticsMapClusteredSourceGeoJsonForEntries(
      entries: entries,
      markerAssetSignature: 'sig-1',
    );

    final beerCoordinates = _featureCoordinates(
      _featureById(geoJson, 'beer-1'),
    );
    final wineCoordinates = _featureCoordinates(
      _featureById(geoJson, 'wine-1'),
    );

    expect(beerCoordinates[0], closeTo(13.40496, 0.0000001));
    expect(beerCoordinates[1], closeTo(52.52004, 0.0000001));
    expect(wineCoordinates[0], closeTo(11.57549, 0.0000001));
    expect(wineCoordinates[1], closeTo(48.13743, 0.0000001));
  });

  test('detail source uses fanned out marker coordinates', () {
    final entries = <DrinkEntry>[
      _entry(
        id: 'beer-1',
        category: DrinkCategory.beer,
        latitude: 52.52004,
        longitude: 13.40496,
      ),
      _entry(
        id: 'wine-1',
        category: DrinkCategory.wine,
        latitude: 52.52003,
        longitude: 13.40499,
      ),
    ];

    final clusteredGeoJson = statisticsMapClusteredSourceGeoJsonForEntries(
      entries: entries,
      markerAssetSignature: 'sig-1',
    );
    final detailGeoJson = statisticsMapDetailSourceGeoJsonForEntries(
      entries: entries,
      markerAssetSignature: 'sig-1',
    );

    final clusteredBeer = _featureCoordinates(
      _featureById(clusteredGeoJson, 'beer-1'),
    );
    final clusteredWine = _featureCoordinates(
      _featureById(clusteredGeoJson, 'wine-1'),
    );
    final detailBeer = _featureCoordinates(
      _featureById(detailGeoJson, 'beer-1'),
    );
    final detailWine = _featureCoordinates(
      _featureById(detailGeoJson, 'wine-1'),
    );

    expect(detailBeer, isNot(clusteredBeer));
    expect(detailWine, isNot(clusteredWine));
    expect(detailBeer, isNot(detailWine));
  });

  test('generated feature properties resolve tapped entry and category', () {
    final geoJson = statisticsMapDetailSourceGeoJsonForEntries(
      entries: <DrinkEntry>[
        _entry(
          id: 'cocktail-1',
          category: DrinkCategory.cocktails,
          latitude: 40.7128,
          longitude: -74.0060,
        ),
      ],
      markerAssetSignature: 'sig-1',
    );

    final properties = _featureProperties(_featureById(geoJson, 'cocktail-1'));

    expect(properties['entryId'], 'cocktail-1');
    expect(properties['category'], DrinkCategory.cocktails.storageValue);
    expect(properties['markerImageId'], isA<String>());
    expect((properties['markerImageId']! as String), isNotEmpty);
  });

  test('cluster count layer properties keep the label centered', () {
    final properties = statisticsMapClusterCountLayerProperties(
      labelColor: Colors.white,
    ).toJson();

    expect(properties['text-font'], const <String>[
      'Open Sans Bold',
      'Arial Unicode MS Bold',
    ]);
    expect(properties['text-anchor'], 'center');
    expect(properties['text-justify'], 'center');
    expect(properties['text-offset'], <double>[0, -0.08]);
    expect(properties['text-size'], 16);
    expect(properties['text-halo-width'], 0.0);
    expect(properties.containsKey('text-halo-color'), isFalse);
    expect(properties['text-allow-overlap'], isTrue);
    expect(properties['text-ignore-placement'], isTrue);
  });
}
