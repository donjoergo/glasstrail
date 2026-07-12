import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/app.dart';
import 'src/deep_link_service.dart';
import 'src/location_service.dart';
import 'src/photo_service.dart';
import 'src/push_notification_service.dart';

void main() {
  // Required before any platform channel calls (push notifications, plugins)
  // since the framework binding doesn't exist until the engine is attached.
  WidgetsFlutterBinding.ensureInitialized();
  // Manrope ships bundled under google_fonts/ for every weight the app
  // renders, so this only ever hits the bundled assets — disabling runtime
  // fetching turns a missing weight into a loud exception instead of a
  // silent network call to Google's font CDN.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Created here (before runApp) because platform push setup is async and
  // must complete before the widget tree can wire up notification handling;
  // the heavier Supabase/Firebase bootstrap itself happens later, inside
  // GlassTrailBootstrapApp, so the first frame can render without blocking.
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
