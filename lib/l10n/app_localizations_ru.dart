// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Доходы и Расходы';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get addTransaction => 'Добавить транзакцию';

  @override
  String get title => 'Название';

  @override
  String get amount => 'Сумма';

  @override
  String get type => 'Тип';

  @override
  String get income => 'Доход';

  @override
  String get expense => 'Расход';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String get pleaseEnterTitle => 'Пожалуйста, введите название';

  @override
  String get pleaseEnterAmount => 'Пожалуйста, введите сумму';

  @override
  String get pleaseEnterValidNumber => 'Пожалуйста, введите корректное число';

  @override
  String get noTransactions => 'Нет транзакций';

  @override
  String get recentTransactions => 'Последние транзакции';

  @override
  String get monthlySummary => 'Месячный отчет';

  @override
  String get category => 'Категория';

  @override
  String get amountMustBeGreaterThanZero => 'Сумма должна быть больше нуля';

  @override
  String get pleaseSelectCategory => 'Пожалуйста, выберите категорию';

  @override
  String get invalidAmountFormat => 'Неверный формат суммы';

  @override
  String get settings => 'Настройки';

  @override
  String get theme => 'Тема';

  @override
  String get language => 'Язык';

  @override
  String get systemDefault => 'Системная';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get darkTheme => 'Темная тема';

  @override
  String get lightTheme => 'Светлая тема';
}
