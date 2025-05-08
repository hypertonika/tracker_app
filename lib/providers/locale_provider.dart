import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_prefs_service.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  bool _useSystemLocale = true;

  Locale? get locale => _useSystemLocale ? null : _locale;
  bool get useSystemLocale => _useSystemLocale;
  String get currentLanguage => _locale?.languageCode ?? 'system';

  void setLocale(Locale locale) {
    _locale = locale;
    _useSystemLocale = false;
    notifyListeners();
    _savePrefs();
  }

  void useSystemSettings() {
    _useSystemLocale = true;
    notifyListeners();
    _savePrefs();
  }

  void _savePrefs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final language = _useSystemLocale ? 'system' : _locale?.languageCode ?? 'system';
      // Для темы используем 'system' (или можно получить из ThemeProvider)
      UserPrefsService().savePrefs('system', language);
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      default:
        return 'System';
    }
  }

  void setLocaleFromString(String code) {
    if (code == 'system') {
      useSystemSettings();
    } else {
      setLocale(Locale(code));
    }
  }
} 