import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_localizations.dart';
import 'app_routes.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'models.dart';
import 'photo_service.dart';
import 'screens/add_drink_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_shell.dart';

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
