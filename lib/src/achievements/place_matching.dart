/// Pure home/work place matching for achievement evaluation.
///
/// Matching requires precise location metadata and a fixed 50 m radius
/// (`SavedPlace.matchRadiusMeters`); see `spec.md` Place and Country Rules.
library;

import 'dart:math' as math;

import 'catalog_models.dart';

const double _earthRadiusMeters = 6371000;

/// Great-circle distance between two coordinates, in meters.
double distanceMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  final double phi1 = lat1 * math.pi / 180;
  final double phi2 = lat2 * math.pi / 180;
  final double deltaPhi = (lat2 - lat1) * math.pi / 180;
  final double deltaLambda = (lon2 - lon1) * math.pi / 180;

  final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
      math.cos(phi1) * math.cos(phi2) * math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusMeters * c;
}

/// True if `(lat, lon)` is within [SavedPlace.matchRadiusMeters] of any
/// place in [places]. Callers should already have filtered [places] to the
/// relevant [SavedPlaceType] and pre-filtered entries to precise-location
/// ones before calling this.
bool matchesAnyPlace({
  required double lat,
  required double lon,
  required List<SavedPlace> places,
}) {
  for (final SavedPlace place in places) {
    final double distance = distanceMeters(
      lat1: lat,
      lon1: lon,
      lat2: place.latitude,
      lon2: place.longitude,
    );
    if (distance <= SavedPlace.matchRadiusMeters) {
      return true;
    }
  }
  return false;
}

/// Counts how many entries (given as precise `(lat, lon)` pairs; callers
/// must have already excluded non-precise entries) fall within range of any
/// currently saved place of [placeType].
///
/// "Currently saved" includes active and archived places (future progress
/// still counts drinks at a place you used to call Home), but excludes any
/// place that has been deleted outright, since deleted places are simply
/// absent from [places].
int countEntriesMatchingPlaceType({
  required List<(double lat, double lon)> preciseEntryCoordinates,
  required SavedPlaceType placeType,
  required List<SavedPlace> places,
}) {
  final List<SavedPlace> relevant =
      places.where((SavedPlace p) => p.placeType == placeType).toList(growable: false);
  if (relevant.isEmpty) {
    return 0;
  }
  int count = 0;
  for (final (double lat, double lon) coordinate in preciseEntryCoordinates) {
    if (matchesAnyPlace(lat: coordinate.$1, lon: coordinate.$2, places: relevant)) {
      count += 1;
    }
  }
  return count;
}
