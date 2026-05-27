import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/screens/statistics_screen.dart';

DrinkEntry _entry({
  required String id,
  required DrinkCategory category,
  required double latitude,
  required double longitude,
  String? drinkId,
}) {
  return DrinkEntry(
    id: id,
    userId: 'user-1',
    drinkId: drinkId ?? 'drink-$id',
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

  test('marker asset signatures change when a custom drink accent changes', () {
    final entry = _entry(
      id: 'custom-1',
      drinkId: 'custom-drink-1',
      category: DrinkCategory.cocktails,
      latitude: 48.1372,
      longitude: 11.5756,
    );

    final pinkSignature = statisticsMapMarkerAssetSignatureForEntries(
      theme: ThemeData.light(),
      entries: <DrinkEntry>[entry],
      drinks: const <DrinkDefinition>[
        DrinkDefinition(
          id: 'custom-drink-1',
          name: 'Sunset Spritz',
          category: DrinkCategory.cocktails,
          accentColorHex: '#EC4899',
          ownerUserId: 'user-1',
        ),
      ],
    );
    final tealSignature = statisticsMapMarkerAssetSignatureForEntries(
      theme: ThemeData.light(),
      entries: <DrinkEntry>[entry],
      drinks: const <DrinkDefinition>[
        DrinkDefinition(
          id: 'custom-drink-1',
          name: 'Sunset Spritz',
          category: DrinkCategory.cocktails,
          accentColorHex: '#14B8A6',
          ownerUserId: 'user-1',
        ),
      ],
    );

    expect(pinkSignature, isNot(tealSignature));
  });

  test('overlapping marker indexes handle invalid tap index', () {
    final indexes = statisticsMapOverlappingMarkerIndexes(
      offsets: const <Offset>[Offset(0, 0), Offset(10, 0)],
      tappedIndex: -1,
    );

    expect(indexes, isEmpty);
  });

  test('resolve marker tap zooms when multiple markers overlap', () {
    final resolution = resolveStatisticsMapMarkerTap(
      offsets: const <Offset>[Offset(0, 0), Offset(4, 3)],
      tappedIndex: 0,
      currentZoom: 10,
      overlapRadius: 6,
    );

    expect(resolution, StatisticsMapTapResolution.zoomIn);
  });

  test('resolve marker tap opens sheet at max zoom', () {
    final resolution = resolveStatisticsMapMarkerTap(
      offsets: const <Offset>[Offset(0, 0), Offset(4, 3)],
      tappedIndex: 0,
      currentZoom: 18.5,
      overlapRadius: 6,
      zoomResolutionMaxZoom: 18.5,
    );

    expect(resolution, StatisticsMapTapResolution.openSheet);
  });

  test('cluster groups merge offsets through transitive neighbors', () {
    final groups = statisticsMapClusterGroups(
      offsets: const <Offset>[
        Offset(0, 0),
        Offset(20, 0),
        Offset(40, 0),
        Offset(200, 0),
      ],
      clusterRadius: 25,
    );

    expect(groups, const <List<int>>[
      <int>[0, 1, 2],
      <int>[3],
    ]);
  });

  test('standalone marker indexes return isolated markers only', () {
    final indexes = statisticsMapStandaloneMarkerIndexes(
      offsets: const <Offset>[
        Offset(0, 0),
        Offset(20, 0),
        Offset(40, 0),
        Offset(200, 0),
      ],
      isolationRadius: 25,
    );

    expect(indexes, const <int>[3]);
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
