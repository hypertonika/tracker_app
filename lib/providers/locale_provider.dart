import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/translations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_prefs_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale';
  late SharedPreferences _prefs;
  late Translations _translations;
  Locale _locale = const Locale('en');
  bool _useSystemLocale = true;
  final UserPrefsService _userPrefsService = UserPrefsService();

  LocaleProvider() {
    _translations = Translations(_locale);
    _initLocale();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _initLocale();
    });
  }

  Locale? get locale => _useSystemLocale ? null : _locale;
  bool get useSystemLocale => _useSystemLocale;
  String get currentLanguage => _locale.languageCode;
  Translations get translations => _translations;

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('ru'),
    Locale('kk'),
  ];

  Future<void> _initLocale() async {
    _prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await _userPrefsService.loadPrefs();
      if (prefs != null && prefs['language'] != null) {
        final languageCode = prefs['language']!;
        if (languageCode == 'system') {
          _useSystemLocale = true;
        } else {
          _useSystemLocale = false;
          _locale = Locale(languageCode);
        }
      } else {
        final String? savedLocale = _prefs.getString(_localeKey);
        if (savedLocale != null) {
          _useSystemLocale = false;
          _locale = Locale(savedLocale);
        } else {
          _useSystemLocale = true;
        }
      }
    } else {
      final guestData = await _userPrefsService.loadGuestData();
      final guestLanguage = guestData['language'] as String;
      if (guestLanguage == 'system') {
        _useSystemLocale = true;
      } else {
        _useSystemLocale = false;
        _locale = Locale(guestLanguage);
      }
    }
    _translations = Translations(_locale);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale && !_useSystemLocale) return;

    _useSystemLocale = false;
    _locale = locale;
    _translations = Translations(locale);
    await _prefs.setString(_localeKey, locale.languageCode);
    _savePrefs();
    notifyListeners();
  }

  void useSystemSettings() {
    if (_useSystemLocale) return;

    _useSystemLocale = true;
    _savePrefs();
    notifyListeners();
  }

  void _savePrefs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final language = _useSystemLocale ? 'system' : _locale.languageCode;
      _userPrefsService.saveLanguageToFirestore(user.uid, language);
    } else {
      _userPrefsService.saveGuestLanguage(_useSystemLocale ? 'system' : _locale.languageCode);
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