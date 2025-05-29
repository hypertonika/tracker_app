import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_prefs_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;
  final UserPrefsService _userPrefsService = UserPrefsService(); // Создаем экземпляр сервиса

  ThemeProvider() {
    // _loadThemeMode(); // Удаляем прямой вызов загрузки
    _initTheme(); // Добавляем новый метод инициализации
    // Слушаем изменения состояния авторизации
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _initTheme(); // Переинициализируем тему при изменении пользователя
    });
  }

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

  Future<void> _initTheme() async {
     _prefs = await SharedPreferences.getInstance(); // Убедимся, что prefs инициализирован
     final user = FirebaseAuth.instance.currentUser;
     if (user != null) {
        // Пользователь авторизован - пытаемся загрузить из Firebase
        final prefs = await _userPrefsService.loadPrefs();
        if (prefs != null && prefs['theme'] != null) {
           final themeModeString = prefs['theme']!;
           if (themeModeString == 'system') {
              _useSystemTheme = true;
           } else {
              _useSystemTheme = false;
              _themeMode = ThemeMode.values.firstWhere(
                 (e) => e.toString().split('.').last == themeModeString,
                 orElse: () => ThemeMode.system,
              );
           }
        } else {
           // Если в Firebase нет настроек, используем системные или локальные (если были)
           final String? savedThemeMode = _prefs.getString(_themeModeKey);
           if (savedThemeMode != null) {
              _useSystemTheme = false;
              _themeMode = ThemeMode.values.firstWhere(
                 (e) => e.toString() == savedThemeMode,
                 orElse: () => ThemeMode.system,
              );
           } else {
              _useSystemTheme = true; // По умолчанию системные
           }
        }
     } else {
        // Пользователь гость - загружаем из SharedPreferences (гостевые данные)
        final guestData = await _userPrefsService.loadGuestData();
        final guestTheme = guestData['theme'] as String;
         if (guestTheme == 'system') {
              _useSystemTheme = true;
           } else {
              _useSystemTheme = false;
              _themeMode = ThemeMode.values.firstWhere(
                 (e) => e.toString().split('.').last == guestTheme,
                 orElse: () => ThemeMode.system,
              );
           }
     }
     notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode && !_useSystemTheme) return; // Проверяем также системные

    _useSystemTheme = false; // При ручной установке темы отключаем системные настройки
    _themeMode = themeMode;
    await _prefs.setString(_themeModeKey, themeMode.toString()); // Сохраняем в SharedPreferences (на всякий случай)
    _savePrefs(); // Сохраняем в Firebase (если авторизован)
    notifyListeners();
  }

  void useSystemSettings() {
     if (_useSystemTheme) return; // Если уже системные, выходим

    _useSystemTheme = true;
     // Не сохраняем в SharedPreferences, так как используем системные
    _savePrefs(); // Сохраняем 'system' в Firebase
    notifyListeners();
  }

  void _savePrefs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final theme = _useSystemTheme ? 'system' : _themeMode.toString().split('.').last;
      // _userPrefsService.savePrefs('theme', theme); // Удаляем старый вызов
      _userPrefsService.saveThemeToFirestore(user.uid, theme); // Используем новый метод
    } else {
       // Сохраняем для гостя в SharedPreferences
      _userPrefsService.saveGuestTheme(_useSystemTheme ? 'system' : _themeMode.toString().split('.').last); // Сохраняем только гостевую тему
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

  ThemeData get themeData {
    if (_useSystemTheme) {
      // Use system theme
      return ThemeData.fallback();
    }
    return _themeMode == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
  }
} 