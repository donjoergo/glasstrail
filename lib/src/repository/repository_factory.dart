import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_config.dart';
import '../cache/bootstrap_cache_store.dart';
import '../cache/media_cache_store.dart';
import 'app_repository.dart';
import 'cached_app_repository.dart';
import 'local_app_repository.dart';
import 'supabase_app_repository.dart';

Future<AppRepository> createRepository({BackendConfig? backendConfig}) async {
  final config = backendConfig ?? BackendConfig.fromEnvironment();
  if (!config.isSupabaseConfigured) {
    return LocalAppRepository.create();
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  final cacheStore = await BootstrapCacheStore.create();
  final mediaCacheStore = await MediaCacheStore.shared();
  final repository = SupabaseAppRepository(Supabase.instance.client);
  return CachedAppRepository(
    delegate: repository,
    cacheStore: cacheStore,
    mediaCacheStore: mediaCacheStore,
    loadLocalAuthSession: () {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        return null;
      }
      return LocalAuthSession(id: authUser.id, email: authUser.email ?? '');
    },
  );
}
