import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'import_file_service.dart';
import 'locale_memory.dart';
import 'location_service.dart';
import 'photo_service.dart';
import 'route_memory.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required this.photoService,
    required this.importFileService,
    required this.locationService,
    required this.routeMemory,
    required this.localeMemory,
    required super.child,
  }) : super(notifier: controller);

  final PhotoService photoService;
  final ImportFileService importFileService;
  final LocationService locationService;
  final RouteMemory routeMemory;
  final LocaleMemory localeMemory;

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

  static LocationService locationServiceOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from widget tree.');
    return scope!.locationService;
  }

  static ImportFileService importFileServiceOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from widget tree.');
    return scope!.importFileService;
  }

  static RouteMemory routeMemoryOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from widget tree.');
    return scope!.routeMemory;
  }

  static LocaleMemory localeMemoryOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from widget tree.');
    return scope!.localeMemory;
  }
}
