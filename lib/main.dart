import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_team_sync.dart' as team_sync;

// Default entry point delegates to TeamSync
void main() {
  team_sync.main();
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
