import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale_catalog.dart';

class LocaleMemory {
  LocaleMemory._(this._preferences)
    : _localeCode = _normalizeLocaleCode(
        _preferences?.getString(_localeCodeKey),
      );

  LocaleMemory.disabled() : this._(null);

  static const _localeCodeKey = 'glasstrail.last_locale';

  final SharedPreferences? _preferences;
  String _localeCode;

  static Future<LocaleMemory> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocaleMemory._(preferences);
  }

  String get localeCode => _localeCode;

  Future<void> rememberLocale(String localeCode) async {
    final normalized = _normalizeLocaleCode(localeCode);
    if (_localeCode == normalized) {
      return;
    }
    _localeCode = normalized;
    await _preferences?.setString(_localeCodeKey, normalized);
  }

  static String _normalizeLocaleCode(String? localeCode) {
    return AppLocaleCatalog.normalizeCode(localeCode);
  }
}
