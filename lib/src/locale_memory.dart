import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale_catalog.dart';

class LocaleMemory {
  LocaleMemory._(this._preferences)
    : _localeCode = _normalizeLocaleCode(
        _preferences?.getString(_localeCodeKey),
      );

  // Allows callers (e.g. tests, or contexts where SharedPreferences isn't
  // available/desired) to use this class without persistence; all reads
  // then fall back to the normalized default locale and writes are no-ops.
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

  // Routed through AppLocaleCatalog so a stored code from a locale that's
  // since been dropped/renamed (or was never valid) always resolves to a
  // supported locale rather than surfacing an unrecognized code to the UI.
  static String _normalizeLocaleCode(String? localeCode) {
    return AppLocaleCatalog.normalizeCode(localeCode);
  }
}
