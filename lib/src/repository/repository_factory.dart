import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_config.dart';
import '../cache/bootstrap_cache_store.dart';
import '../cache/media_cache_store.dart';
import 'app_repository.dart';
import 'cached_app_repository.dart';
import 'local_app_repository.dart';
import 'supabase_app_repository.dart';

// Single place that decides which AppRepository implementation the rest of
// the app gets, keeping that decision (and the wiring between Supabase,
// caching, and local fallback) out of UI/state code.
Future<AppRepository> createRepository({BackendConfig? backendConfig}) async {
  final config = backendConfig ?? BackendConfig.fromEnvironment();
  // No Supabase credentials configured (e.g. local dev without a .env, or a
  // deliberately offline build): fall back to the local-only repository
  // instead of failing to start.
  if (!config.isSupabaseConfigured) {
    return LocalAppRepository.create();
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );

  final cacheStore = await BootstrapCacheStore.create();
  final mediaCacheStore = await MediaCacheStore.shared();
  final repository = SupabaseAppRepository(Supabase.instance.client);
  // Only the remote (Supabase) backend is wrapped with caching — the local
  // backend already reads/writes SharedPreferences synchronously enough
  // that an extra cache layer would add complexity without a real benefit.
  return CachedAppRepository(
    delegate: repository,
    cacheStore: cacheStore,
    mediaCacheStore: mediaCacheStore,
    // Supplies the cache layer with the authoritative "who is signed in"
    // check straight from the Supabase SDK, so cache validity is judged
    // against the real auth state rather than a value the cache itself
    // could get out of sync with.
    loadLocalAuthSession: () {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        return null;
      }
      return LocalAuthSession(id: authUser.id, email: authUser.email ?? '');
    },
  );
}
