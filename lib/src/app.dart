import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_controller.dart';
import 'app_localizations.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'models.dart';
import 'photo_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';

class GlassTrailApp extends StatelessWidget {
  const GlassTrailApp({
    super.key,
    required this.controller,
    required this.photoService,
  });

  final AppController controller;
  final PhotoService photoService;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      photoService: photoService,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
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
            home: controller.isAuthenticated
                ? const HomeShell()
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
