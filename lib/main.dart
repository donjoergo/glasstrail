import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/deep_link_service.dart';
import 'src/location_service.dart';
import 'src/photo_service.dart';
import 'src/push_notification_service.dart';

Future<void> main() async {
  // Required before any platform channel calls (push notifications, plugins)
  // since the framework binding doesn't exist until the engine is attached.
  WidgetsFlutterBinding.ensureInitialized();
  // Created here (before runApp) because platform push setup is async and
  // must complete before the widget tree can wire up notification handling;
  // the heavier Supabase/Firebase bootstrap itself happens later, inside
  // GlassTrailBootstrapApp, so the first frame can render without blocking.
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
