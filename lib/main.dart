import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/location_service.dart';
import 'src/photo_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const GlassTrailBootstrapApp(
      photoService: FileSelectorPhotoService(),
      locationService: PlatformLocationService(),
    ),
  );
}
