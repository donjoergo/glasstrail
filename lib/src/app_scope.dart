import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'import_file_service.dart';
import 'locale_memory.dart';
import 'location_service.dart';
import 'photo_service.dart';
import 'route_memory.dart';

// Root dependency-injection point for the widget tree: bundles the
// AppController (via InheritedNotifier, so descendants rebuild on its
// notifyListeners()) alongside platform-service singletons (photo, import
// file, location) and on-device memory (route/locale), avoiding threading
// these through every constructor.
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

  // The assert exists purely to give a clear failure message in debug
  // builds ("AppScope missing from widget tree") instead of an opaque
  // null-check crash; it's stripped in release, so the `!` below still has
  // to do the real work there.
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
