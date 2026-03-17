import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/app.dart';
import 'package:glasstrail/src/app_controller.dart';
import 'package:glasstrail/src/photo_service.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

class TestPhotoService extends PhotoService {
  const TestPhotoService({this.path = '/tmp/mock-image.png'});

  final String? path;

  @override
  Future<String?> pickImage() async => path;
}

Future<AppController> buildTestController({
  Map<String, Object> initialValues = const <String, Object>{},
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(initialValues);
  final preferences = await SharedPreferences.getInstance();
  final repository = LocalAppRepository(preferences);
  return AppController.bootstrapWithRepository(repository);
}

Future<GlassTrailApp> buildTestApp({
  Map<String, Object> initialValues = const <String, Object>{},
}) async {
  final controller = await buildTestController(initialValues: initialValues);
  return GlassTrailApp(
    controller: controller,
    photoService: const TestPhotoService(),
  );
}
