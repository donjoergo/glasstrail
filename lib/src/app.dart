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
import 'locale_memory.dart';
import 'location_service.dart';
import 'models.dart';
import 'photo_service.dart';
import 'route_memory.dart';
import 'screens/add_drink_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_shell.dart';

const _appDisplayTitle = 'Glass Trail';
const _brandIconAsset = 'assets/icon/app_icon.png';

class GlassTrailBootstrapApp extends StatefulWidget {
  const GlassTrailBootstrapApp({
    super.key,
    required this.photoService,
    this.locationService = const PlatformLocationService(),
    this.backendConfig,
    this.initialRoute,
    this.controllerFuture,
    this.routeMemoryFuture,
    this.localeMemoryFuture,
  });

  final PhotoService photoService;
  final LocationService locationService;
  final BackendConfig? backendConfig;
  final String? initialRoute;
  final Future<AppController>? controllerFuture;
  final Future<RouteMemory>? routeMemoryFuture;
  final Future<LocaleMemory>? localeMemoryFuture;

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
        AppController.bootstrap(backendConfig: widget.backendConfig);
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
            locationService: widget.locationService,
            routeMemory: bootstrapData.routeMemory,
            localeMemory: bootstrapData.localeMemory,
            initialRoute: widget.initialRoute,
          );
        }
        return _BootstrapShell(
          hasError: snapshot.hasError,
          initialRoute: widget.initialRoute,
          localeCode: snapshot.data?.localeCode ?? 'en',
        );
      },
    );
  }

  Future<_BootstrapData> _loadBootstrapData(
    Future<AppController> controllerFuture,
  ) async {
    final controller = await controllerFuture;
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
    );
  }
}

class GlassTrailApp extends StatelessWidget {
  GlassTrailApp({
    super.key,
    required this.controller,
    required this.photoService,
    this.locationService = const PlatformLocationService(),
    RouteMemory? routeMemory,
    LocaleMemory? localeMemory,
    this.initialRoute,
  }) : routeMemory = routeMemory ?? RouteMemory.disabled(),
       localeMemory = localeMemory ?? LocaleMemory.disabled();

  final AppController controller;
  final PhotoService photoService;
  final LocationService locationService;
  final RouteMemory routeMemory;
  final LocaleMemory localeMemory;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      photoService: photoService,
      locationService: locationService,
      routeMemory: routeMemory,
      localeMemory: localeMemory,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          Route<dynamic> buildRoute(RouteSettings settings) {
            final routeName = AppRoutes.normalize(settings.name);
            unawaited(routeMemory.rememberRoute(routeName));
            return MaterialPageRoute<void>(
              settings: RouteSettings(
                name: routeName,
                arguments: settings.arguments,
              ),
              builder: (_) => _AppRouteScreen(routeName: routeName),
            );
          }

          return MaterialApp(
            title: _appDisplayTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.settings.themePreference.themeMode,
            locale: Locale(controller.settings.localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateInitialRoutes: (initialRouteName) {
              final routeName = routeMemory.resolveInitialRoute(
                initialRoute ?? initialRouteName,
              );
              return <Route<dynamic>>[
                buildRoute(RouteSettings(name: routeName)),
              ];
            },
            onGenerateRoute: buildRoute,
            onUnknownRoute: (_) => buildRoute(
              RouteSettings(
                name: controller.isAuthenticated
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
  });

  final AppController controller;
  final RouteMemory routeMemory;
  final LocaleMemory localeMemory;
  final String localeCode;
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

    if (!controller.isAuthenticated) {
      if (normalizedRoute == AppRoutes.auth) {
        return const AuthScreen();
      }
      return _RouteRedirectScreen(
        targetRoute: AppRoutes.auth,
        arguments: normalizedRoute,
      );
    }

    return switch (normalizedRoute) {
      AppRoutes.feed ||
      AppRoutes.statistics ||
      AppRoutes.bar ||
      AppRoutes.profile => HomeShell(routeName: normalizedRoute),
      AppRoutes.addDrink => const AddDrinkScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
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
