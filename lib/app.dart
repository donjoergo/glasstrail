import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:glasstrail/pages/add_drink_page.dart';
import 'package:glasstrail/pages/app_shell.dart';
import 'package:glasstrail/pages/feed_page.dart';
import 'package:glasstrail/pages/map_page.dart';
import 'package:glasstrail/pages/profile_page.dart';
import 'package:glasstrail/pages/settings_page.dart';
import 'package:glasstrail/pages/stats_page.dart';
import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/state/app_controller.dart';
import 'package:glasstrail/theme/app_theme.dart';
import 'package:glasstrail/onboarding/onboarding_page.dart';

class GlassTrailApp extends StatefulWidget {
  const GlassTrailApp({super.key});

  @override
  State<GlassTrailApp> createState() => _GlassTrailAppState();
}

class _GlassTrailAppState extends State<GlassTrailApp> {
  late final AppController _controller;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _controller = AppController();

    _router = GoRouter(
      initialLocation: '/feed',
      refreshListenable: _controller,
      redirect: (context, state) {
        final onboarding = state.matchedLocation.startsWith('/onboarding');

        if (!_controller.onboardingComplete && !onboarding) {
          return '/onboarding';
        }

        if (_controller.onboardingComplete && onboarding) {
          return '/feed';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingPage(controller: _controller),
        ),
        GoRoute(
          path: '/onboarding/:step',
          builder: (context, state) => OnboardingPage(controller: _controller),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(
              controller: _controller,
              location: state.uri.path,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => FeedPage(controller: _controller),
            ),
            GoRoute(
              path: '/map',
              builder: (context, state) => MapPage(controller: _controller),
            ),
            GoRoute(
              path: '/stats',
              builder: (context, state) => StatsPage(controller: _controller),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfilePage(controller: _controller),
            ),
          ],
        ),
        GoRoute(
          path: '/drink/new',
          builder: (context, state) => AddDrinkPage(controller: _controller),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsPage(controller: _controller),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          routerConfig: _router,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _controller.themeMode,
          locale: _controller.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
