import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class Translations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  Translations(this.locale);

  static Translations of(BuildContext context) {
    return Localizations.of<Translations>(context, Translations)!;
  }

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('lib/l10n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class TranslationsDelegate extends LocalizationsDelegate<Translations> {
  const TranslationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'kk'].contains(locale.languageCode);
  }

  @override
  Future<Translations> load(Locale locale) async {
    Translations translations = Translations(locale);
    await translations.load();
    return translations;
  }

  @override
  bool shouldReload(TranslationsDelegate old) => false;
} 