import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/beer_with_me_import.dart';

void main() {
  group('BeerWithMe import parsing', () {
    test('covers every glass type from the sample export', () {
      final sample = File(
        'test/support/history_Gesamt_sample.json',
      ).readAsStringSync();
      final exportFile = parseBeerWithMeExportFile(sample);

      final glassTypes = exportFile.rows
          .map(decodeBeerWithMeImportRow)
          .map((record) => record.glassType)
          .toSet();

      expect(
        glassTypes.difference(beerWithMeGlassTypeToDrinkId.keys.toSet()),
        isEmpty,
      );
      expect(glassTypes, hasLength(25));
    });

    test('normalizes no_address and missing coordinates to null', () {
      final exportFile = parseBeerWithMeExportFile('''
        [
          {
            "id": 172120176,
            "timestamp": "2022-06-06T22:55:15.000+02:00",
            "glassType": "WineRose",
            "address": "no_address"
          }
        ]
      ''');

      final record = decodeBeerWithMeImportRow(exportFile.rows.single);

      expect(record.sourceId, '172120176');
      expect(record.glassType, 'WineRose');
      expect(record.locationLatitude, isNull);
      expect(record.locationLongitude, isNull);
      expect(record.locationAddress, isNull);
      expect(
        record.consumedAt,
        DateTime.parse('2022-06-06T22:55:15.000+02:00').toLocal(),
      );
    });

    test(
      'converts multiline addresses into comma-separated GlassTrail format',
      () {
        final exportFile = parseBeerWithMeExportFile('''
          [
            {
              "id": 2,
              "timestamp": "2022-06-06T23:10:00.000+02:00",
              "glassType": "Beer",
              "latitude": 49.5635995,
              "longitude": 10.8827774,
              "address": "Am Buck 19\\nHerzogenaurach\\nDeutschland"
            }
          ]
        ''');

        final record = decodeBeerWithMeImportRow(exportFile.rows.single);

        expect(
          record.locationAddress,
          'Am Buck 19, Herzogenaurach, Deutschland',
        );
      },
    );

    test('reports missing timestamps as row errors', () {
      final exportFile = parseBeerWithMeExportFile('''
        [
          {"id": 1, "glassType": "Beer"}
        ]
      ''');

      expect(
        () => decodeBeerWithMeImportRow(exportFile.rows.single),
        throwsA(
          isA<BeerWithMeImportRowException>().having(
            (error) => error.code,
            'code',
            BeerWithMeImportRowErrorCode.missingTimestamp,
          ),
        ),
      );
    });
  });
}
