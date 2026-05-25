import 'dart:async';

import '../app_controller.dart';
import '../backend_config.dart';
import '../push_notification_service.dart';
import '../repository/repository_factory.dart';

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
    unawaited(controller.startBootstrapReconciliation());
    return controller;
  }
}
