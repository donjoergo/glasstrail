import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'photo_service.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required this.photoService,
    required super.child,
  }) : super(notifier: controller);

  final PhotoService photoService;

  static AppController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from widget tree.');
    return scope!.notifier!;
  }

  static PhotoService photoServiceOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from widget tree.');
    return scope!.photoService;
  }
}
