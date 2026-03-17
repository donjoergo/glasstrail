import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/app_controller.dart';
import 'src/photo_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.bootstrap();
  runApp(
    GlassTrailApp(
      controller: controller,
      photoService: const FileSelectorPhotoService(),
    ),
  );
}
