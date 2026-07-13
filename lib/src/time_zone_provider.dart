import 'package:flutter_timezone/flutter_timezone.dart';

abstract interface class TimeZoneProvider {
  Future<String?> getLocalTimeZoneIdentifier();
}

class PlatformTimeZoneProvider implements TimeZoneProvider {
  const PlatformTimeZoneProvider();

  @override
  Future<String?> getLocalTimeZoneIdentifier() async {
    try {
      final identifier = (await FlutterTimezone.getLocalTimezone()).identifier
          .trim();
      return identifier.isEmpty ? null : identifier;
    } catch (_) {
      // flutter_timezone relies on a native platform channel that can be
      // unavailable (web, unsupported platform) or fail unexpectedly on
      // some devices; returning null lets callers fall back to the
      // device's default/system timezone instead of crashing.
      return null;
    }
  }
}
