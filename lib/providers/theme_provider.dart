import 'package:flutter/material.dart';

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
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _useSystemTheme = false;
    notifyListeners();
  }

  void useSystemSettings() {
    _useSystemTheme = true;
    notifyListeners();
  }
} 