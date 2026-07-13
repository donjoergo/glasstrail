import 'dart:async';

import '../app_controller.dart';
import '../backend_config.dart';
import '../push_notification_service.dart';
import '../repository/repository_factory.dart';

// Small seam between GlassTrailBootstrapApp and repository/controller
// construction, mainly so tests can inject a pre-built controllerFuture and
// skip this real backend-touching path entirely.
class AppBootstrapLoader {
  const AppBootstrapLoader({
    this.backendConfig,
    this.pushNotificationService = const DisabledPushNotificationService(),
  });

  final BackendConfig? backendConfig;
  final PushNotificationService pushNotificationService;

  Future<AppController> loadController() async {
    final repository = await createRepository(backendConfig: backendConfig);
    final controller = await AppController.bootstrapWithRepository(
      repository,
      pushNotificationService: pushNotificationService,
    );
    // Deliberately not awaited: the controller is usable immediately with
    // whatever it loaded from cache/bootstrap, and reconciling against the
    // backend (validating the session, refreshing stale domains) happens in
    // the background so the UI isn't blocked on a network round trip at
    // startup.
    unawaited(controller.startBootstrapReconciliation());
    return controller;
  }
}
