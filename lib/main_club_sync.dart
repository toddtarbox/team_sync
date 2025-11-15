import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/app_config.dart';
import 'package:team_sync/firebase_options_club.dart'; // ClubSync Firebase
import 'package:team_sync/router_club.dart';
import 'package:team_sync/services/subscription_service.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show ThemeNotifier;

void main() async {
  // Initialize as ClubSync (multi-team club app)
  AppConfig.initialize(AppConfig.clubSync);

  // Enable clean URLs for web (removes # from URL)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

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

  // ClubSync now uses the shared team-sync-soccer Firebase project
  // Both TeamSync and ClubSync apps share the same Firebase project but use different data structures
  // ClubSync uses: Clubs, ClubTeams, ClubSeasons, ClubGames, ClubPlayers, ClubEvents
  // TeamSync uses: subscriptionIds/{uid}/databases/{db}/...
  await Firebase.initializeApp(
    options: DefaultFirebaseOptionsClub.currentPlatform,
  );
  await SubscriptionService.instance.initialize();

  runApp(ChangeNotifierProvider(
    create: (_) => ThemeNotifier(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp.router(
          title: AppConfig.current.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: routerClub,
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
