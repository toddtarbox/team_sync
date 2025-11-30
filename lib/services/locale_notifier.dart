import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages locale/language selection with persistence
class LocaleNotifier extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleNotifier() {
    _loadPreferences();
  }

  /// Load the saved locale preference
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
    // If null, system default will be used
  }

  /// Save locale preference
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_locale != null) {
      await prefs.setString('languageCode', _locale!.languageCode);
    } else {
      await prefs.remove('languageCode');
    }
  }

  /// Set a specific locale
  void setLocale(Locale? locale) {
    _locale = locale;
    notifyListeners();
    _savePreferences();
  }

  /// Reset to system default
  void resetToSystemDefault() {
    _locale = null;
    notifyListeners();
    _savePreferences();
  }
}
