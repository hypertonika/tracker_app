import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_prefs_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;

  ThemeMode get themeMode => _useSystemTheme ? ThemeMode.system : _themeMode;
  bool get useSystemTheme => _useSystemTheme;

  void toggleTheme() {
    if (_useSystemTheme) {
      _useSystemTheme = false;
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
    _savePrefs();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _useSystemTheme = false;
    notifyListeners();
    _savePrefs();
  }

  void useSystemSettings() {
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