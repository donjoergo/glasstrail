class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  static const defaultSupabaseUrl = 'https://lzuxlcfjnekgjukqxoza.supabase.co';
  static const defaultSupabasePublishableKey =
      'sb_publishable_VInDXR9KppRTFuR_lgcUyw_ZHx8f3-o';

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static const empty = BackendConfig(supabaseUrl: '', supabaseAnonKey: '');

  static BackendConfig fromEnvironment() {
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
