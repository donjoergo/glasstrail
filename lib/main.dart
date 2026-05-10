import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/deep_link_service.dart';
import 'src/location_service.dart';
import 'src/photo_service.dart';
import 'src/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pushNotificationService = await createPlatformPushNotificationService();
  runApp(
    GlassTrailBootstrapApp(
      photoService: const FileSelectorPhotoService(),
      locationService: const PlatformLocationService(),
      deepLinkService: const PlatformDeepLinkService(),
      pushNotificationService: pushNotificationService,
    ),
  );
}
