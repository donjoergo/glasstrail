import 'dart:convert';

import 'models.dart';

const String beerWithMeImportSource = 'beer_with_me';

// Maps the "Beer With Me" app's internal glass-type identifiers (fixed,
// English, camel-case strings baked into their export format) onto our own
// drink catalog ids. Keys must match their export exactly, including odd
// casing/pairings (e.g. "Weinschorle" and "Spritzer" both map to the same
// wine-spritzer drink) since we have no control over how their app names them.
const Map<String, String> beerWithMeGlassTypeToDrinkId = <String, String>{
  'Beer': 'beer-classic',
  'BeerCan': 'beer-can',
  'BeerWheat': 'beer-weizen',
  'BeerStout': 'beer-stout',
  'BeerMass': 'beer-mass',
  'BeerGoassMass': 'beer-goassmass',
  'BeerKolsch': 'beer-kölsch',
  'WineRed': 'wine-red-wine',
  'WineWhite': 'wine-white-wine',
  'WineRose': 'wine-rosé-wine',
  'Spritzer': 'wine-spritzer',
  'Weinschorle': 'wine-wine-spritzer',
  'WineMulled': 'wine-mulled-wine',
  'Champagne': 'sparklingWines-champagne',
  'Grog': 'longdrinks-longdrink',
  'GrogGT': 'longdrinks-gin-tonic',
  'GrogCubaLibre': 'longdrinks-cuba-libre',
  'Cocktail': 'cocktails-cocktail',
  'Rum': 'spirits-rum',
  'Cognac': 'spirits-cognac',
  'Whisky': 'spirits-whiskey',
  'Shot': 'shots-shot',
  'Cider': 'appleWines-cider',
  'CiderRibbed': 'appleWines-cider',
  'Seltzer': 'appleWines-hard-seltzer',
};

class BeerWithMeImportFile {
  const BeerWithMeImportFile({required this.rows});

  final List<BeerWithMeImportRow> rows;
}

class BeerWithMeImportRow {
  const BeerWithMeImportRow({required this.rowNumber, required this.payload});

  final int rowNumber;
  final Object? payload;
}

enum BeerWithMeImportRowErrorCode {
  invalidEntry,
  missingId,
  missingGlassType,
  missingTimestamp,
  invalidTimestamp,
}

class BeerWithMeImportRowException implements Exception {
  const BeerWithMeImportRowException(
    this.code, {
    required this.rowNumber,
    this.sourceId,
    this.glassType,
  });

  final BeerWithMeImportRowErrorCode code;
  final int rowNumber;
  final String? sourceId;
  final String? glassType;
}

class BeerWithMeImportRecord {
  const BeerWithMeImportRecord({
    required this.rowNumber,
    required this.sourceId,
    required this.glassType,
    required this.consumedAt,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
  });

  final int rowNumber;
  final String sourceId;
  final String glassType;
  final DateTime consumedAt;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;
}

class BeerWithMeImportError {
  const BeerWithMeImportError({
    required this.rowNumber,
    required this.message,
    this.sourceId,
    this.glassType,
  });

  final int rowNumber;
  final String message;
  final String? sourceId;
  final String? glassType;
}

class BeerWithMeImportResult {
  const BeerWithMeImportResult({
    required this.totalRows,
    required this.processedCount,
    required this.importedCount,
    required this.skippedDuplicateCount,
    required this.errors,
    this.wasCancelled = false,
  });

  final int totalRows;
  final int processedCount;
  final int importedCount;
  final int skippedDuplicateCount;
  final List<BeerWithMeImportError> errors;
  final bool wasCancelled;

  int get errorCount => errors.length;
}

BeerWithMeImportFile parseBeerWithMeExportFile(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List<dynamic>) {
    throw const FormatException('Expected a JSON array.');
  }

  return BeerWithMeImportFile(
    rows: decoded
        .asMap()
        .entries
        .map(
          (entry) => BeerWithMeImportRow(
            // 1-indexed so row numbers shown in error/result UI match what a
            // user would count if they opened the export file themselves.
            rowNumber: entry.key + 1,
            payload: entry.value,
          ),
        )
        .toList(growable: false),
  );
}

BeerWithMeImportRecord decodeBeerWithMeImportRow(BeerWithMeImportRow row) {
  final payload = row.payload;
  if (payload is! Map) {
    throw BeerWithMeImportRowException(
      BeerWithMeImportRowErrorCode.invalidEntry,
      rowNumber: row.rowNumber,
    );
  }

  final json = Map<String, dynamic>.from(payload);
  // Validation order matters: id is checked first because it's what we use
  // to detect duplicates on re-import, so a row without it can't be deduped
  // or safely skipped even if the rest of its data looks fine.
  final sourceId = _readRequiredStringishId(json['id']);
  if (sourceId == null) {
    throw BeerWithMeImportRowException(
      BeerWithMeImportRowErrorCode.missingId,
      rowNumber: row.rowNumber,
      glassType: _readTrimmedString(json['glassType']),
    );
  }

  final glassType = _readTrimmedString(json['glassType']);
  if (glassType == null) {
    throw BeerWithMeImportRowException(
      BeerWithMeImportRowErrorCode.missingGlassType,
      rowNumber: row.rowNumber,
      sourceId: sourceId,
    );
  }

  final timestamp = _readTrimmedString(json['timestamp']);
  if (timestamp == null) {
    throw BeerWithMeImportRowException(
      BeerWithMeImportRowErrorCode.missingTimestamp,
      rowNumber: row.rowNumber,
      sourceId: sourceId,
      glassType: glassType,
    );
  }

  // Export timestamps are ISO-8601; converting to local time keeps imported
  // entries consistent with drinks logged directly in this app, which are
  // always stored/displayed in the device's local time.
  final consumedAt = DateTime.tryParse(timestamp)?.toLocal();
  if (consumedAt == null) {
    throw BeerWithMeImportRowException(
      BeerWithMeImportRowErrorCode.invalidTimestamp,
      rowNumber: row.rowNumber,
      sourceId: sourceId,
      glassType: glassType,
    );
  }

  final latitude = _readDouble(json['latitude']);
  final longitude = _readDouble(json['longitude']);
  final locationAddress = _normalizeAddress(json['address']);

  return BeerWithMeImportRecord(
    rowNumber: row.rowNumber,
    sourceId: sourceId,
    glassType: glassType,
    consumedAt: consumedAt,
    // A lone lat or lon is useless (and the source app can emit one without
    // the other for rows with partial location data), so we drop both
    // rather than store a half-valid coordinate.
    locationLatitude: latitude != null && longitude != null ? latitude : null,
    locationLongitude: latitude != null && longitude != null ? longitude : null,
    locationAddress: locationAddress,
  );
}

String? _readRequiredStringishId(Object? value) {
  if (value == null) {
    return null;
  }
  // The source export isn't guaranteed to encode ids as JSON strings (some
  // rows carry numeric ids), so we coerce via toString() rather than
  // requiring a String type, then treat blank/whitespace-only as absent.
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String? _readTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

String? _normalizeAddress(Object? value) {
  final normalized = _readTrimmedString(value);
  // 'no_address' is the literal sentinel the source app writes for entries
  // without a resolved address, rather than omitting the field or using null.
  if (normalized == null || normalized == 'no_address') {
    return null;
  }
  return normalizeLocationAddress(normalized);
}
