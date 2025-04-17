import 'package:flutter/material.dart';

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
  }

  void useSystemSettings() {
    _useSystemLocale = true;
    notifyListeners();
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
} 