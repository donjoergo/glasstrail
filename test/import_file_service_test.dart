import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/import_file_service.dart';

void main() {
  group('decodeImportFileContents', () {
    test('decodes utf8 encoded exports', () {
      final contents = decodeImportFileContents(
        utf8.encode('{"address":"Köln, Deutschland"}'),
      );

      expect(contents, '{"address":"Köln, Deutschland"}');
    });

    test('falls back to latin1 for legacy encoded exports', () {
      final contents = decodeImportFileContents(
        latin1.encode('{"address":"München, Deutschland"}'),
      );

      expect(contents, '{"address":"München, Deutschland"}');
    });

    test('strips a leading utf8 bom before parsing json', () {
      final bytes = <int>[
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('{"address":"Düsseldorf, Deutschland"}'),
      ];

      final contents = decodeImportFileContents(bytes);

      expect(contents, '{"address":"Düsseldorf, Deutschland"}');
    });
  });
}
