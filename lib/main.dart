import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_sync/firebase_options.dart';
import 'package:team_sync/router.dart';
import 'package:team_sync/services/subscription_service.dart';

import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SubscriptionService.instance.initialize();

  runApp(ChangeNotifierProvider(
    create: (_) => ThemeNotifier(),
    child: const MyApp(),
  ));
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp.router(
          routerConfig: router,
          title: 'TeamSync',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(22, 148, 123, 1),
              brightness: Brightness.light,
            ),
            cardTheme: const CardThemeData(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade900,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(22, 148, 123, 1),
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade900,
              elevation: 0,
            ),
          ),
          themeMode: themeNotifier.themeMode,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
            child: child!,
          ),
        );
      },
    );
  }
}
