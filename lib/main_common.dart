import 'dart:async';
import 'package:showcaseview/showcaseview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_sync/app_config.dart';
import 'package:team_sync/router.dart';
import 'package:team_sync/services/database_sharing_service.dart';
import 'package:team_sync/services/locale_notifier.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/services/sport_strategy.dart';
import 'package:team_sync/l10n/app_localizations.dart';

Future<void> mainCommon(
    SportStrategy strategy, FirebaseOptions Function() optionsBuilder) async {
  // Use PathUrlStrategy to remove the hash (#) from the URL
  usePathUrlStrategy();

  // Initialize as TeamSync (single-team app)
  AppConfig.initialize(AppConfig.soccer);

  // Initialize SportStrategy
  SportStrategy.initialize(strategy);

  await _initializeApp(optionsBuilder);
}

Future<void> _initializeApp(FirebaseOptions Function() optionsBuilder) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load();
    } catch (e) {
      debugPrint('dotenv load failed (OK if using system env vars): $e');
    }
  }

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: optionsBuilder(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase already initialized: $e');
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }
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
          title: SportStrategy.current.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: SportStrategy.current.primaryColor),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              iconTheme:
                  IconThemeData(color: SportStrategy.current.primaryColor),
              actionsIconTheme:
                  IconThemeData(color: SportStrategy.current.primaryColor),
              titleTextStyle: TextStyle(
                color: SportStrategy.current.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: SportStrategy.current.primaryColor,
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
            return ShowCaseWidget(
              builder: (context) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: [
                  const Breakpoint(start: 0, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                  const Breakpoint(
                      start: 1921, end: double.infinity, name: '4K'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAutoMode = false;
  Timer? _timer;

  ThemeMode get themeMode => _themeMode;
  bool get isAutoMode => _isAutoMode;

  ThemeNotifier() {
    _loadPreferences();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateThemeForAutoMode() {
    final hour = DateTime.now().hour;
    // Switch to dark mode at 6 PM (18:00), and light mode at 6 AM (06:00)
    final newMode = (hour >= 6 && hour < 18) ? ThemeMode.light : ThemeMode.dark;
    if (_themeMode != newMode) {
      _themeMode = newMode;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    // Update theme immediately and then every minute
    _updateThemeForAutoMode();
    _timer = Timer.periodic(
        const Duration(minutes: 1), (_) => _updateThemeForAutoMode());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
    _isAutoMode = prefs.getBool('isAutoMode') ?? false;

    if (_isAutoMode) {
      _startTimer();
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setBool('isAutoMode', _isAutoMode);
  }

  void setThemeMode(ThemeMode mode) {
    _isAutoMode = false;
    _stopTimer();

    _themeMode = mode;
    notifyListeners();
    _savePreferences();
  }

  void setAutoMode(bool isAuto) {
    _isAutoMode = isAuto;
    if (_isAutoMode) {
      _startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
    _savePreferences();
  }
}
