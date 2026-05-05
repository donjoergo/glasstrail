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
      return null;
    }
  }
}
