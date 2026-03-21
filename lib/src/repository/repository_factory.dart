import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_config.dart';
import 'app_repository.dart';
import 'local_app_repository.dart';
import 'supabase_app_repository.dart';

Future<AppRepository> createRepository({
  BackendConfig? backendConfig,
}) async {
  final config = backendConfig ?? BackendConfig.fromEnvironment();
  if (!config.isSupabaseConfigured) {
    return LocalAppRepository.create();
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  return SupabaseAppRepository(Supabase.instance.client);
}
