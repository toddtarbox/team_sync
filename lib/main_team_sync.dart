import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Import for PathUrlStrategy
import 'package:team_sync/app_config.dart';
import 'package:team_sync/firebase_options.dart';
import 'package:team_sync/router.dart';
import 'package:team_sync/services/database_sharing_service.dart';
import 'package:team_sync/services/locale_notifier.dart';
import 'package:team_sync/services/subscription_service.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show ThemeNotifier;

void main() async {
  // Use PathUrlStrategy to remove the hash (#) from the URL
  usePathUrlStrategy();

  // Initialize as TeamSync (single-team app)
  AppConfig.initialize(AppConfig.teamSync);

  await _initializeApp();
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load();
    } catch (e) {
      debugPrint('dotenv load failed (OK if using system env vars): $e');
    }
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SubscriptionService.instance.initialize();

  // Register user in lookup table if already signed in
  if (!kIsWeb) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email != null) {
        await DatabaseSharingService.instance.registerUserInLookup();
      }
    } catch (e) {
      debugPrint('Failed to register user in lookup: $e');
    }
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ChangeNotifierProvider(create: (_) => LocaleNotifier()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, LocaleNotifier>(
      builder: (context, themeNotifier, localeNotifier, child) {
        return MaterialApp.router(
          key: ValueKey(localeNotifier.locale?.languageCode ?? 'system'),
          title: AppConfig.current.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.green),
              actionsIconTheme: IconThemeData(color: Colors.green),
              titleTextStyle: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode,
          locale: localeNotifier.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) {
            return ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            );
          },
        );
      },
    );
  }
}
