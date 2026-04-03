import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'app_language.dart';

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
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationFetchResult();
      }

      final accuracyStatus = await _readLocationAccuracy();
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
    return switch (resolveFrameworkLocaleCode(localeCode)) {
      kGermanLocaleCode => 'de_DE',
      _ => 'en_US',
    };
  }

  String? _formatPlacemark(Placemark placemark) {
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
