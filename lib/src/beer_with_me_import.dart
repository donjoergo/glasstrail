import 'dart:convert';

import 'models.dart';

const String beerWithMeImportSource = 'beer_with_me';

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
    required this.achievementLocalDate,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
  });

  final int rowNumber;
  final String sourceId;
  final String glassType;
  final DateTime consumedAt;

  /// The calendar day implied by the source export's own timestamp,
  /// independent of the importing device's timezone. See
  /// `docs/achievements/spec.md`: "BeerWithMe imports must preserve the
  /// calendar day implied by the source timestamp, not the importing
  /// device timezone."
  final DateTime achievementLocalDate;
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

  // Parse without converting to the importing device's current timezone:
  // the raw parsed value's calendar day is either the naive-local day as
  // authored (no zone suffix in the string) or the UTC day of the exact
  // instant (an explicit 'Z'/offset suffix) -- either way, a stable day
  // that does not depend on which device runs the import.
  final rawParsed = DateTime.tryParse(timestamp);
  if (rawParsed == null) {
    throw BeerWithMeImportRowException(
      BeerWithMeImportRowErrorCode.invalidTimestamp,
      rowNumber: row.rowNumber,
      sourceId: sourceId,
      glassType: glassType,
    );
  }
  final consumedAt = rawParsed.toLocal();
  final achievementLocalDate = DateTime(
    rawParsed.year,
    rawParsed.month,
    rawParsed.day,
  );

  final latitude = _readDouble(json['latitude']);
  final longitude = _readDouble(json['longitude']);
  final locationAddress = _normalizeAddress(json['address']);

  return BeerWithMeImportRecord(
    rowNumber: row.rowNumber,
    sourceId: sourceId,
    glassType: glassType,
    consumedAt: consumedAt,
    achievementLocalDate: achievementLocalDate,
    locationLatitude: latitude != null && longitude != null ? latitude : null,
    locationLongitude: latitude != null && longitude != null ? longitude : null,
    locationAddress: locationAddress,
  );
}

String? _readRequiredStringishId(Object? value) {
  if (value == null) {
    return null;
  }
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
  if (normalized == null || normalized == 'no_address') {
    return null;
  }
  return normalizeLocationAddress(normalized);
}
