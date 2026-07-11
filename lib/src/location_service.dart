import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class EntryLocationData {
  const EntryLocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;
}

class LocationFetchResult {
  const LocationFetchResult({
    this.location,
    this.accuracyStatus = LocationAccuracyStatus.unknown,
  });

  final EntryLocationData? location;
  final LocationAccuracyStatus accuracyStatus;
}

abstract class LocationService {
  const LocationService();

  Future<LocationFetchResult> fetchCurrentLocation({
    required String localeCode,
  });

  Future<bool> openAppSettings();
}

class PlatformLocationService extends LocationService {
  const PlatformLocationService();

  @override
  Future<LocationFetchResult> fetchCurrentLocation({
    required String localeCode,
  }) async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return const LocationFetchResult();
      }

      var permission = await Geolocator.checkPermission();
      // Only prompt when the permission is a plain "denied" — requesting
      // again when it's already "deniedForever" would just re-trigger the
      // OS dialog needlessly (it won't ask twice on some platforms) instead
      // of directing the user to app settings.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationFetchResult();
      }

      final accuracyStatus = await _readLocationAccuracy();
      // High accuracy is requested explicitly because "approximate" location
      // (iOS 14+ / Android precise-location toggle) yields addresses that
      // are too imprecise for reverse geocoding to a street-level result.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LocationFetchResult(
        accuracyStatus: accuracyStatus,
        location: EntryLocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          address: await _resolveAddress(
            latitude: position.latitude,
            longitude: position.longitude,
            localeCode: localeCode,
          ),
        ),
      );
      // geolocator/geocoding can throw any of these depending on platform
      // (desktop/web without location support, missing native
      // implementation, OS-level permission/service errors) — logging a
      // drink should never fail just because location couldn't be
      // captured, so every failure mode degrades to "no location" instead
      // of propagating.
    } on LocationServiceDisabledException {
      return const LocationFetchResult();
    } on PermissionDeniedException {
      return const LocationFetchResult();
    } on UnsupportedError {
      return const LocationFetchResult();
    } on MissingPluginException {
      return const LocationFetchResult();
    } on PlatformException {
      return const LocationFetchResult();
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return Geolocator.openAppSettings();
    } on UnsupportedError {
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<LocationAccuracyStatus> _readLocationAccuracy() async {
    try {
      return await Geolocator.getLocationAccuracy();
    } on UnsupportedError {
      return LocationAccuracyStatus.unknown;
    } on MissingPluginException {
      return LocationAccuracyStatus.unknown;
    } on PlatformException {
      return LocationAccuracyStatus.unknown;
    }
  }

  Future<String?> _resolveAddress({
    required double latitude,
    required double longitude,
    required String localeCode,
  }) async {
    try {
      // The geocoding plugin needs a full locale identifier (e.g. "de_DE"),
      // not just the app's short language code, to return
      // localized/correctly formatted placemark fields.
      await setLocaleIdentifier(_localeIdentifier(localeCode));
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } on UnsupportedError {
      return null;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return null;
      }
      return _formatPlacemark(placemarks.first);
    } on NoResultFoundException {
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }

  String _localeIdentifier(String localeCode) {
    return switch (localeCode) {
      'de' => 'de_DE',
      _ => 'en_US',
    };
  }

  String? _formatPlacemark(Placemark placemark) {
    // Different platforms/regions populate different placemark fields for
    // the "street" concept (thoroughfare is the standard field, but it's
    // often empty on some platforms where `street` or even the generic
    // `name` is what's actually filled in), so each is tried in order of
    // reliability.
    final streetName = _firstNonEmpty(<String?>[
      placemark.thoroughfare,
      placemark.street,
      placemark.name,
    ]);
    final houseNumber = _normalized(placemark.subThoroughfare);
    final city = _firstNonEmpty(<String?>[
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]);
    final postalCode = _normalized(placemark.postalCode);
    final country = _normalized(placemark.country);

    final segments = <String>[
      if (streetName != null && houseNumber != null) '$streetName $houseNumber',
      if (streetName != null && houseNumber == null) streetName,
      if (streetName == null && houseNumber != null) houseNumber,
      if (postalCode != null && city != null) '$postalCode $city',
      if (postalCode != null && city == null) postalCode,
      if (postalCode == null && city != null) city,
      ?country,
    ];
    if (segments.isEmpty) {
      return null;
    }
    return segments.join(', ');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = _normalized(value);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalized(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
