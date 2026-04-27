import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import 'app_controller.dart';
import 'app_routes.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'backend_config.dart';
import 'deep_link_service.dart';
import 'import_file_service.dart';
import 'locale_memory.dart';
import 'location_service.dart';
import 'models.dart';
import 'photo_service.dart';
import 'push_notification_service.dart';
import 'route_memory.dart';
import 'screens/add_drink_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/friend_profile_screen.dart';
import 'screens/home_shell.dart';
import 'screens/notifications_screen.dart';

const _appDisplayTitle = 'Glass Trail';
const _brandIconAsset = 'assets/icon/app_icon.png';

class GlassTrailBootstrapApp extends StatefulWidget {
  const GlassTrailBootstrapApp({
    super.key,
    required this.photoService,
    this.importFileService = const FileSelectorImportFileService(),
    this.locationService = const PlatformLocationService(),
    this.backendConfig,
    this.initialRoute,
    this.controllerFuture,
    this.routeMemoryFuture,
    this.localeMemoryFuture,
    this.deepLinkService = const DisabledDeepLinkService(),
    this.pushNotificationService = const DisabledPushNotificationService(),
  });

  final PhotoService photoService;
  final ImportFileService importFileService;
  final LocationService locationService;
  final BackendConfig? backendConfig;
  final String? initialRoute;
  final Future<AppController>? controllerFuture;
  final Future<RouteMemory>? routeMemoryFuture;
  final Future<LocaleMemory>? localeMemoryFuture;
  final DeepLinkService deepLinkService;
  final PushNotificationService pushNotificationService;

  @override
  State<GlassTrailBootstrapApp> createState() => _GlassTrailBootstrapAppState();
}

class _GlassTrailBootstrapAppState extends State<GlassTrailBootstrapApp> {
  late Future<_BootstrapData> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    final controllerFuture =
        widget.controllerFuture ??
        AppController.bootstrap(
          backendConfig: widget.backendConfig,
          pushNotificationService: widget.pushNotificationService,
        );
    _bootstrapFuture = _loadBootstrapData(controllerFuture);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final bootstrapData = snapshot.data!;
          return GlassTrailApp(
            controller: bootstrapData.controller,
            photoService: widget.photoService,
            importFileService: widget.importFileService,
            locationService: widget.locationService,
            routeMemory: bootstrapData.routeMemory,
            localeMemory: bootstrapData.localeMemory,
            deepLinkService: widget.deepLinkService,
            pushNotificationService: widget.pushNotificationService,
            initialRoute: bootstrapData.initialRoute,
          );
        }
        return _BootstrapShell(
          hasError: snapshot.hasError,
          initialRoute: widget.initialRoute ?? _routeFromLaunchUri(),
          localeCode: snapshot.data?.localeCode ?? 'en',
        );
      },
    );
  }

  Future<_BootstrapData> _loadBootstrapData(
    Future<AppController> controllerFuture,
  ) async {
    final controller = await controllerFuture;
    final launchRoute = widget.initialRoute ?? _routeFromLaunchUri();
    final initialPushOpen = launchRoute == null
        ? await widget.pushNotificationService.consumeInitialOpen()
        : null;
    await _markNotificationOpenRead(controller, initialPushOpen);
    final initialRoute =
        launchRoute ??
        initialPushOpen?.routeName ??
        await _routeFromInitialDeepLink(widget.deepLinkService);
    final Future<RouteMemory> routeMemoryFuture =
        widget.routeMemoryFuture ??
        (kIsWeb
            ? RouteMemory.create()
            : Future<RouteMemory>.value(RouteMemory.disabled()));
    final Future<LocaleMemory> localeMemoryFuture =
        widget.localeMemoryFuture ?? LocaleMemory.create();
    final routeMemory = await routeMemoryFuture;
    final localeMemory = await localeMemoryFuture;
    var bootstrapLocaleCode = localeMemory.localeCode;
    if (controller.isAuthenticated) {
      bootstrapLocaleCode = controller.settings.localeCode;
      await localeMemory.rememberLocale(bootstrapLocaleCode);
    } else if (controller.settings.localeCode != bootstrapLocaleCode) {
      await controller.updateSettings(
        controller.settings.copyWith(localeCode: bootstrapLocaleCode),
      );
    }
    return _BootstrapData(
      controller: controller,
      routeMemory: routeMemory,
      localeMemory: localeMemory,
      localeCode: bootstrapLocaleCode,
      initialRoute: initialRoute,
    );
  }
}

String? _routeFromLaunchUri() {
  if (!kIsWeb) {
    return null;
  }
  final route = Uri.base.queryParameters['route'];
  if (route == null || route.trim().isEmpty) {
    return null;
  }
  return AppRoutes.normalize(route);
}

Future<String?> _routeFromInitialDeepLink(
  DeepLinkService deepLinkService,
) async {
  try {
    return routeFromDeepLink(await deepLinkService.getInitialUri());
  } catch (_) {
    return null;
  }
}

class GlassTrailApp extends StatefulWidget {
  GlassTrailApp({
    super.key,
    required this.controller,
    required this.photoService,
    this.importFileService = const FileSelectorImportFileService(),
    this.locationService = const PlatformLocationService(),
    RouteMemory? routeMemory,
    LocaleMemory? localeMemory,
    this.initialRoute,
    this.deepLinkService = const DisabledDeepLinkService(),
    this.pushNotificationService = const DisabledPushNotificationService(),
  }) : routeMemory = routeMemory ?? RouteMemory.disabled(),
       localeMemory = localeMemory ?? LocaleMemory.disabled();

  final AppController controller;
  final PhotoService photoService;
  final ImportFileService importFileService;
  final LocationService locationService;
  final RouteMemory routeMemory;
  final LocaleMemory localeMemory;
  final String? initialRoute;
  final DeepLinkService deepLinkService;
  final PushNotificationService pushNotificationService;

  @override
  State<GlassTrailApp> createState() => _GlassTrailAppState();
}

class _GlassTrailAppState extends State<GlassTrailApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<PushNotificationOpen>? _notificationOpenSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToDeepLinks();
    _subscribeToNotificationRoutes();
  }

  @override
  void didUpdateWidget(covariant GlassTrailApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deepLinkService != widget.deepLinkService) {
      unawaited(_deepLinkSubscription?.cancel());
      _subscribeToDeepLinks();
    }
    if (oldWidget.pushNotificationService != widget.pushNotificationService) {
      unawaited(_notificationOpenSubscription?.cancel());
      _subscribeToNotificationRoutes();
    }
  }

  @override
  void dispose() {
    unawaited(_deepLinkSubscription?.cancel());
    unawaited(_notificationOpenSubscription?.cancel());
    super.dispose();
  }

  void _subscribeToDeepLinks() {
    _deepLinkSubscription = widget.deepLinkService.uriStream.listen(
      _openDeepLink,
      onError: (_) {},
    );
  }

  void _subscribeToNotificationRoutes() {
    _notificationOpenSubscription = widget
        .pushNotificationService
        .openedNotifications
        .listen((open) => unawaited(_openNotification(open)), onError: (_) {});
  }

  void _openDeepLink(Uri uri) {
    final route = routeFromDeepLink(uri);
    if (route == null) {
      return;
    }
    _openRouteName(route);
  }

  void _openRouteName(String routeName) {
    final route = AppRoutes.normalize(routeName);
    void openRoute() {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }
      navigator.pushNamedAndRemoveUntil(route, (_) => false);
    }

    if (_navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openRoute());
      return;
    }
    openRoute();
  }

  Future<void> _openNotification(PushNotificationOpen open) async {
    await _markNotificationOpenRead(widget.controller, open);
    _openRouteName(open.routeName);
    unawaited(widget.controller.refreshFriendConnections());
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      photoService: widget.photoService,
      importFileService: widget.importFileService,
      locationService: widget.locationService,
      routeMemory: widget.routeMemory,
      localeMemory: widget.localeMemory,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          Route<dynamic> buildRoute(RouteSettings settings) {
            final routeName = AppRoutes.normalize(settings.name);
            unawaited(widget.routeMemory.rememberRoute(routeName));
            final routeSettings = RouteSettings(
              name: routeName,
              arguments: settings.arguments,
            );
            if (AppRoutes.isHomeShellRoute(routeName)) {
              return PageRouteBuilder<void>(
                settings: routeSettings,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, _, _) => _AppRouteScreen(routeName: routeName),
              );
            }
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (_) => _AppRouteScreen(routeName: routeName),
            );
          }

          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: _appDisplayTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: widget.controller.settings.themePreference.themeMode,
            locale: Locale(widget.controller.settings.localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateInitialRoutes: (initialRouteName) {
              final routeName = widget.routeMemory.resolveInitialRoute(
                widget.initialRoute ?? initialRouteName,
              );
              return <Route<dynamic>>[
                buildRoute(RouteSettings(name: routeName)),
              ];
            },
            onGenerateRoute: buildRoute,
            onUnknownRoute: (_) => buildRoute(
              RouteSettings(
                name: widget.controller.isAuthenticated
                    ? AppRoutes.feed
                    : AppRoutes.auth,
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _markNotificationOpenRead(
  AppController controller,
  PushNotificationOpen? open,
) async {
  final notificationId = open?.notificationId;
  if (notificationId == null || notificationId.isEmpty) {
    return;
  }
  await controller.markNotificationsRead(<String>[notificationId]);
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({
    required this.hasError,
    required this.localeCode,
    this.initialRoute,
  });

  final bool hasError;
  final String localeCode;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    Route<dynamic> buildRoute(RouteSettings settings) {
      final routeName = AppRoutes.normalize(settings.name);
      return MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName, arguments: settings.arguments),
        builder: (_) => _BootstrapScreen(hasError: hasError),
      );
    }

    return MaterialApp(
      title: _appDisplayTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateInitialRoutes: (initialRouteName) {
        final routeName = AppRoutes.normalize(initialRoute ?? initialRouteName);
        return <Route<dynamic>>[buildRoute(RouteSettings(name: routeName))];
      },
      onGenerateRoute: buildRoute,
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.primary.withValues(alpha: 0.14),
              theme.colorScheme.tertiary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Card(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Material(
                        elevation: 16,
                        shadowColor: theme.colorScheme.shadow.withValues(
                          alpha: 0.28,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox.square(
                          dimension: 86,
                          child: Image.asset(
                            _brandIconAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasError ? l10n.somethingWentWrong : l10n.launchingApp,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (hasError)
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 28,
                        )
                      else
                        const SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapData {
  const _BootstrapData({
    required this.controller,
    required this.routeMemory,
    required this.localeMemory,
    required this.localeCode,
    required this.initialRoute,
  });

  final AppController controller;
  final RouteMemory routeMemory;
  final LocaleMemory localeMemory;
  final String localeCode;
  final String? initialRoute;
}

class _AppRouteScreen extends StatelessWidget {
  const _AppRouteScreen({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    final normalizedRoute = AppRoutes.normalize(routeName);

    if (normalizedRoute == AppRoutes.root) {
      return const _RouteRedirectScreen(targetRoute: AppRoutes.feed);
    }

    if (AppRoutes.isFriendProfileRoute(normalizedRoute)) {
      return FriendProfileScreen(
        shareCode: AppRoutes.friendProfileShareCode(normalizedRoute)!,
      );
    }

    if (!controller.isAuthenticated) {
      if (normalizedRoute == AppRoutes.auth) {
        return const AuthScreen();
      }
      return _RouteRedirectScreen(
        targetRoute: AppRoutes.auth,
        arguments: normalizedRoute,
      );
    }

    if (normalizedRoute == AppRoutes.feed ||
        AppRoutes.isStatisticsRoute(normalizedRoute) ||
        AppRoutes.isBarRoute(normalizedRoute) ||
        normalizedRoute == AppRoutes.profile) {
      return HomeShell(routeName: normalizedRoute);
    }

    return switch (normalizedRoute) {
      AppRoutes.addDrink => const AddDrinkScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.notifications => const NotificationsScreen(),
      AppRoutes.auth => const HomeShell(routeName: AppRoutes.feed),
      _ => const HomeShell(routeName: AppRoutes.feed),
    };
  }
}

class _RouteRedirectScreen extends StatefulWidget {
  const _RouteRedirectScreen({required this.targetRoute, this.arguments});

  final String targetRoute;
  final Object? arguments;

  @override
  State<_RouteRedirectScreen> createState() => _RouteRedirectScreenState();
}

class _RouteRedirectScreenState extends State<_RouteRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushReplacementNamed(widget.targetRoute, arguments: widget.arguments);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
