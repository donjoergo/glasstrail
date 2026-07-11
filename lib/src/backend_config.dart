class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  // Fallbacks for local/dev builds run without --dart-define overrides. The
  // publishable key is safe to embed (it's the client-facing anon key, not a
  // secret), so shipping it as a default here is intentional, not an oversight.
  static const defaultSupabaseUrl = 'https://lzuxlcfjnekgjukqxoza.supabase.co';
  static const defaultSupabasePublishableKey =
      'sb_publishable_VInDXR9KppRTFuR_lgcUyw_ZHx8f3-o';

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  // Used by tests/tools that need to force an unconfigured backend without
  // relying on compile-time environment values.
  static const empty = BackendConfig(supabaseUrl: '', supabaseAnonKey: '');

  static BackendConfig fromEnvironment() {
    // String.fromEnvironment reads --dart-define values at compile time, so
    // CI/release builds can point at a different Supabase project without
    // touching source; defaultValue keeps local `flutter run` usable as-is.
    return const BackendConfig(
      supabaseUrl: String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: defaultSupabaseUrl,
      ),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: defaultSupabasePublishableKey,
      ),
    );
  }
}
