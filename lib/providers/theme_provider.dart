import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_prefs_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;

  ThemeMode get themeMode => _themeMode;
  bool get useSystemTheme => _useSystemTheme;

  ThemeData get themeData {
    switch (_themeMode) {
      case ThemeMode.light:
        return ThemeData.light(useMaterial3: true);
      case ThemeMode.dark:
        return ThemeData.dark(useMaterial3: true);
      case ThemeMode.system:
        return ThemeData.light(useMaterial3: true);
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _useSystemTheme = false;
    notifyListeners();
    _savePrefs();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _useSystemTheme = mode == ThemeMode.system;
    notifyListeners();
    _savePrefs();
  }

  void useSystemSettings() {
    _themeMode = ThemeMode.system;
    _useSystemTheme = true;
    notifyListeners();
    _savePrefs();
  }

  void _savePrefs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final theme = _useSystemTheme ? 'system' : (_themeMode == ThemeMode.dark ? 'dark' : 'light');
      // Для языка используем 'system' (или можно получить из LocaleProvider)
      UserPrefsService().savePrefs(theme, 'system');
    }
  }

  void setThemeFromString(String theme) {
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
      _useSystemTheme = false;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
      _useSystemTheme = false;
    } else {
      _useSystemTheme = true;
    }
    notifyListeners();
  }
} 