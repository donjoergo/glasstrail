import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/deep_link_service.dart';
import 'src/location_service.dart';
import 'src/photo_service.dart';
import 'src/push_notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase init must not delay the first frame; it resolves in parallel
  // with bootstrap behind the deferred wrapper.
  final pushNotificationService = DeferredPushNotificationService(
    createPlatformPushNotificationService(),
  );
  runApp(
    GlassTrailBootstrapApp(
      photoService: const FileSelectorPhotoService(),
      locationService: const PlatformLocationService(),
      deepLinkService: const PlatformDeepLinkService(),
      pushNotificationService: pushNotificationService,
    ),
  );
}
