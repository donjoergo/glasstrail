import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_localizations.dart';
import 'app_routes.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'backend_config.dart';
import 'models.dart';
import 'photo_service.dart';
import 'screens/add_drink_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_shell.dart';

class GlassTrailBootstrapApp extends StatefulWidget {
  const GlassTrailBootstrapApp({
    super.key,
    required this.photoService,
    this.backendConfig,
    this.initialRoute,
    this.controllerFuture,
  });

  final PhotoService photoService;
  final BackendConfig? backendConfig;
  final String? initialRoute;
  final Future<AppController>? controllerFuture;

  @override
  State<GlassTrailBootstrapApp> createState() => _GlassTrailBootstrapAppState();
}

class _GlassTrailBootstrapAppState extends State<GlassTrailBootstrapApp> {
  late Future<AppController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture =
        widget.controllerFuture ??
        AppController.bootstrap(backendConfig: widget.backendConfig);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GlassTrailApp(
            controller: snapshot.data!,
            photoService: widget.photoService,
            initialRoute: widget.initialRoute,
          );
        }
        return _BootstrapShell(hasError: snapshot.hasError);
      },
    );
  }
}

class GlassTrailApp extends StatelessWidget {
  const GlassTrailApp({
    super.key,
    required this.controller,
    required this.photoService,
    this.initialRoute,
  });

  final AppController controller;
  final PhotoService photoService;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      photoService: photoService,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          Route<dynamic> buildRoute(RouteSettings settings) {
            final routeName = AppRoutes.normalize(settings.name);
            return MaterialPageRoute<void>(
              settings: RouteSettings(
                name: routeName,
                arguments: settings.arguments,
              ),
              builder: (_) => _AppRouteScreen(routeName: routeName),
            );
          }

          return MaterialApp(
            title: 'GlassTrail',
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
              final routeName = AppRoutes.normalize(
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
  const _BootstrapShell({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassTrail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _BootstrapScreen(hasError: hasError),
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
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.auto_awesome_rounded, size: 28),
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
      return const AuthScreen();
    }

    return switch (normalizedRoute) {
      AppRoutes.feed ||
      AppRoutes.statistics ||
      AppRoutes.profile => HomeShell(routeName: normalizedRoute),
      AppRoutes.addDrink => const AddDrinkScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.auth => const HomeShell(routeName: AppRoutes.feed),
      _ => const HomeShell(routeName: AppRoutes.feed),
    };
  }
}

class _RouteRedirectScreen extends StatefulWidget {
  const _RouteRedirectScreen({required this.targetRoute});

  final String targetRoute;

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
      Navigator.of(context).pushReplacementNamed(widget.targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
