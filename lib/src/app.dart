import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glasstrail/l10n/app_localizations.dart';

import 'app_controller.dart';
import 'app_locale_catalog.dart';
import 'app_routes.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'backend_config.dart';
import 'beer_with_me_import_flow.dart';
import 'bootstrap/app_bootstrap_loader.dart';
import 'browser_theme_color.dart';
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
import 'screens/friend_stats_profile_screen.dart';
import 'screens/home_shell.dart';
import 'screens/notifications_screen.dart';
import 'widgets/app_media.dart';

const _appDisplayTitle = 'Glass Trail';
const _brandIconAsset = 'assets/icon/app_icon.png';

// Two-stage app widget: this stage owns the async bootstrap (controller
// creation, route/locale memory, deep-link/push resolution) and shows a
// splash screen while it runs, then hands off to GlassTrailApp once
// everything the "real" app needs is ready. Keeping this separate avoids
// building the full MaterialApp/router before the controller exists.
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
  late final Future<LocaleMemory> _localeMemoryFuture;
  late Future<_BootstrapData> _bootstrapFuture;
  // Shown on the splash screen before locale memory has loaded; updated
  // asynchronously by _primeBootstrapLocale so the splash text isn't stuck
  // in the wrong language on repeat launches.
  String _bootstrapLocaleCode = AppLocaleCatalog.fallbackCode;

  @override
  void initState() {
    super.initState();
    final controllerFuture =
        widget.controllerFuture ??
        AppBootstrapLoader(
          backendConfig: widget.backendConfig,
          pushNotificationService: widget.pushNotificationService,
        ).loadController();
    _localeMemoryFuture = widget.localeMemoryFuture ?? LocaleMemory.create();
    _primeBootstrapLocale();
    _bootstrapFuture = _loadBootstrapData(
      controllerFuture,
      _localeMemoryFuture,
    );
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
          localeCode: _bootstrapLocaleCode,
        );
      },
    );
  }

  // Fire-and-forget: updates the splash screen's locale as soon as it's
  // known, independently of _loadBootstrapData (which also awaits locale
  // memory but only resolves once the controller/session work is done too).
  // Failures are swallowed since the splash text simply stays at the
  // fallback locale.
  void _primeBootstrapLocale() {
    unawaited(() async {
      try {
        final localeMemory = await _localeMemoryFuture;
        _updateBootstrapLocale(localeMemory.localeCode);
      } catch (_) {}
    }());
  }

  void _updateBootstrapLocale(String localeCode) {
    if (!mounted || _bootstrapLocaleCode == localeCode) {
      return;
    }
    setState(() {
      _bootstrapLocaleCode = localeCode;
    });
  }

  Future<_BootstrapData> _loadBootstrapData(
    Future<AppController> controllerFuture,
    Future<LocaleMemory> localeMemoryFuture,
  ) async {
    final controller = await controllerFuture;
    final launchRoute = widget.initialRoute ?? _routeFromLaunchUri();
    // Only consult the "app opened via push notification" signal if there's
    // no explicit/web launch route — an explicit route always wins, and
    // consumeInitialOpen() is one-shot so it must not be called (and
    // discarded) when we're not going to use its result.
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
    final routeMemory = await routeMemoryFuture;
    final localeMemory = await localeMemoryFuture;
    var bootstrapLocaleCode = localeMemory.localeCode;
    if (controller.isAuthenticated) {
      // Signed-in users' locale lives with their account settings (so it
      // follows them across devices); resync the on-device memory to match
      // in case it drifted (e.g. changed on another device).
      bootstrapLocaleCode = controller.settings.localeCode;
      await localeMemory.rememberLocale(bootstrapLocaleCode);
    } else if (controller.settings.localeCode != bootstrapLocaleCode) {
      // Signed-out: the device-remembered locale is authoritative, so push
      // it into the (default) settings the auth screens will read from.
      await controller.updateSettings(
        controller.settings.copyWith(localeCode: bootstrapLocaleCode),
      );
    }
    _updateBootstrapLocale(bootstrapLocaleCode);
    return _BootstrapData(
      controller: controller,
      routeMemory: routeMemory,
      localeMemory: localeMemory,
      localeCode: bootstrapLocaleCode,
      initialRoute: initialRoute,
    );
  }
}

// Web-only: lets a shared/bookmarked URL like "?route=/feed" deep-link
// straight into a route on load, since the web build doesn't otherwise
// parse the path into an app route.
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

class _GlassTrailAppState extends State<GlassTrailApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<PushNotificationOpen>? _notificationOpenSubscription;
  // Guards the post-sign-up "import from BeerWithMe?" prompt so it can only
  // be shown once the user has gone through an auth transition during this
  // widget's lifetime (see build(), which flips this true whenever the
  // controller is unauthenticated) — otherwise it could fire on an
  // already-signed-in relaunch where the pending-prompt flag happens to be
  // set from a previous session's state.
  bool _postSignUpPromptEligible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _postSignUpPromptEligible = !widget.controller.isAuthenticated;
    _subscribeToDeepLinks();
    _subscribeToNotificationRoutes();
    unawaited(_warmVisibleMedia());
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deepLinkSubscription?.cancel());
    unawaited(_notificationOpenSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only "resumed" matters here: revalidating on every lifecycle
    // transition (inactive, paused, etc.) would fire network requests while
    // the app isn't actually visible to the user.
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.revalidateHotDomainsOnResume());
      unawaited(_warmVisibleMedia());
    }
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
      // Clear the entire navigation stack: a deep link or notification tap
      // should take the user directly to the target screen, not stack it on
      // top of whatever screens happened to be open already.
      navigator.pushNamedAndRemoveUntil(route, (_) => false);
    }

    // The navigator may not exist yet if this fires before the first frame
    // (e.g. a deep link delivered during startup); defer to after the frame
    // so `_navigatorKey.currentState` is guaranteed to be attached.
    if (_navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openRoute());
      return;
    }
    openRoute();
  }

  Future<void> _openNotification(PushNotificationOpen open) async {
    await _markNotificationOpenRead(widget.controller, open);
    _openRouteName(open.routeName);
    await widget.controller.refreshForNotificationOpen(
      routeName: open.routeName,
      notificationId: open.notificationId,
    );
    await _warmVisibleMedia();
  }

  // Pre-fetches images likely to be shown immediately (feed, notifications,
  // profile) into the media cache so the first frames after a cold start or
  // resume don't show placeholders while each image loads individually.
  Future<void> _warmVisibleMedia() {
    return AppMediaResolver.warmImagePaths(
      _bootstrapMediaPaths(widget.controller),
    );
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
          if (!widget.controller.isAuthenticated) {
            _postSignUpPromptEligible = true;
          }

          Route<dynamic> buildRoute(
            RouteSettings settings, {
            required bool allowPostSignUpPrompt,
          }) {
            final routeName = AppRoutes.normalize(settings.name);
            unawaited(widget.routeMemory.rememberRoute(routeName));
            final routeSettings = RouteSettings(
              name: routeName,
              arguments: settings.arguments,
            );
            // Home-shell routes (feed/stats/bar/profile tabs) are all handled
            // by one HomeShell widget that switches tabs internally, so the
            // route transition itself must be instant — an animated page
            // transition here would visibly double up with HomeShell's own
            // tab-switch animation.
            if (AppRoutes.isHomeShellRoute(routeName)) {
              return PageRouteBuilder<void>(
                settings: routeSettings,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, _, _) => _AppRouteScreen(
                  controller: widget.controller,
                  routeName: routeName,
                  allowPostSignUpPrompt:
                      allowPostSignUpPrompt && _postSignUpPromptEligible,
                ),
              );
            }
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (_) => _AppRouteScreen(
                controller: widget.controller,
                routeName: routeName,
                allowPostSignUpPrompt:
                    allowPostSignUpPrompt && _postSignUpPromptEligible,
              ),
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
            builder: (context, child) => _buildBrowserThemeColorSync(
              context,
              child,
              widget.controller.settings.themePreference.themeMode,
            ),
            onGenerateInitialRoutes: (initialRouteName) {
              final routeName = widget.routeMemory.resolveInitialRoute(
                widget.initialRoute ?? initialRouteName,
              );
              return <Route<dynamic>>[
                buildRoute(
                  RouteSettings(name: routeName),
                  allowPostSignUpPrompt: false,
                ),
              ];
            },
            onGenerateRoute: (settings) =>
                buildRoute(settings, allowPostSignUpPrompt: true),
            onUnknownRoute: (_) => buildRoute(
              RouteSettings(
                name: widget.controller.isAuthenticated
                    ? AppRoutes.feed
                    : AppRoutes.auth,
              ),
              allowPostSignUpPrompt: true,
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
      builder: (context, child) =>
          _buildBrowserThemeColorSync(context, child, ThemeMode.system),
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

// Keeps the browser chrome's theme-color (address bar / PWA title bar) in
// sync with the app's actual rendered brightness, including when following
// ThemeMode.system — a no-op on non-web platforms via BrowserThemeColorSync.
Widget _buildBrowserThemeColorSync(
  BuildContext context,
  Widget? child,
  ThemeMode themeMode,
) {
  return BrowserThemeColorSync(
    brightness: _effectiveThemeBrightness(context, themeMode),
    child: child ?? const SizedBox.shrink(),
  );
}

Brightness _effectiveThemeBrightness(
  BuildContext context,
  ThemeMode themeMode,
) {
  return switch (themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => MediaQuery.platformBrightnessOf(context),
  };
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

// Limited to a handful of items per source (roughly what fits on the first
// screen) rather than everything loaded, since warming is meant to avoid
// visible pop-in for what's immediately visible, not to prefetch the whole
// dataset. Deduped via toSet() because the same image (e.g. the user's own
// avatar) can appear as both an author image and a profile image.
List<String> _bootstrapMediaPaths(AppController controller) {
  final paths = <String>[
    ?controller.currentUser?.profileImagePath,
    ...controller.feedPosts
        .take(6)
        .expand((post) => <String?>[post.entry.imagePath, post.authorImagePath])
        .whereType<String>(),
    ...controller.notifications
        .take(6)
        .map((notification) => notification.imagePath)
        .whereType<String>(),
    ...controller.customDrinks
        .take(6)
        .map((drink) => drink.imagePath)
        .whereType<String>(),
  ];
  return paths.toSet().toList(growable: false);
}

class _AppRouteScreen extends StatelessWidget {
  const _AppRouteScreen({
    required this.controller,
    required this.routeName,
    required this.allowPostSignUpPrompt,
  });

  final AppController controller;
  final String routeName;
  final bool allowPostSignUpPrompt;

  @override
  Widget build(BuildContext context) {
    final normalizedRoute = AppRoutes.normalize(routeName);

    if (normalizedRoute == AppRoutes.root) {
      return const _RouteRedirectScreen(targetRoute: AppRoutes.feed);
    }

    if (AppRoutes.isFriendProfileRoute(normalizedRoute)) {
      final child = FriendProfileScreen(
        shareCode: AppRoutes.friendProfileShareCode(normalizedRoute)!,
      );
      if (!controller.isAuthenticated) {
        return child;
      }
      return _wrapAuthenticatedScreen(child, routeName: normalizedRoute);
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

    if (AppRoutes.isFriendStatsProfileRoute(normalizedRoute)) {
      return _wrapAuthenticatedScreen(
        FriendStatsProfileScreen(
          friendUserId: AppRoutes.friendStatsProfileUserId(normalizedRoute)!,
        ),
        routeName: normalizedRoute,
      );
    }

    if (normalizedRoute == AppRoutes.feed ||
        AppRoutes.isStatisticsRoute(normalizedRoute) ||
        AppRoutes.isBarRoute(normalizedRoute) ||
        normalizedRoute == AppRoutes.profile) {
      return _wrapAuthenticatedScreen(
        HomeShell(routeName: normalizedRoute),
        routeName: normalizedRoute,
      );
    }

    return _wrapAuthenticatedScreen(switch (normalizedRoute) {
      AppRoutes.addDrink => const AddDrinkScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.notifications => const NotificationsScreen(),
      AppRoutes.auth => const HomeShell(routeName: AppRoutes.feed),
      _ => const HomeShell(routeName: AppRoutes.feed),
    }, routeName: normalizedRoute);
  }

  Widget _wrapAuthenticatedScreen(Widget child, {required String routeName}) {
    if (!allowPostSignUpPrompt) {
      return child;
    }
    return _AuthenticatedRoutePromptGate(
      controller: controller,
      routeName: routeName,
      child: child,
    );
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

// Wraps authenticated screens to surface the "import from BeerWithMe?"
// prompt exactly once, right after sign-up, without blocking navigation to
// the target screen — the prompt is shown post-frame so the screen itself
// renders first.
class _AuthenticatedRoutePromptGate extends StatefulWidget {
  const _AuthenticatedRoutePromptGate({
    required this.controller,
    required this.routeName,
    required this.child,
  });

  final AppController controller;
  final String routeName;
  final Widget child;

  @override
  State<_AuthenticatedRoutePromptGate> createState() =>
      _AuthenticatedRoutePromptGateState();
}

class _AuthenticatedRoutePromptGateState
    extends State<_AuthenticatedRoutePromptGate> {
  bool _checkedPendingPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showPendingPromptIfNeeded());
    });
  }

  Future<void> _showPendingPromptIfNeeded() async {
    if (!mounted || _checkedPendingPrompt) {
      return;
    }
    _checkedPendingPrompt = true;
    // Skip the auth screen and explicit post-auth redirect targets: those
    // are transient routes the user is bounced through, not places where an
    // interruption like this prompt should appear.
    if (widget.routeName == AppRoutes.auth ||
        AppRoutes.isExplicitPostAuthRedirectRoute(widget.routeName)) {
      return;
    }
    if (!widget.controller.consumePendingPostSignUpBeerWithMePrompt()) {
      return;
    }

    final action = await showBeerWithMePostSignUpPrompt(context);
    if (!mounted || action != BeerWithMePostSignUpPromptAction.importExport) {
      return;
    }

    await startBeerWithMeImportFlow(context, showProgressDialog: true);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
