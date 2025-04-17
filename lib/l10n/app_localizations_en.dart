// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Income & Expenses';

  @override
  String get welcome => 'Welcome';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get title => 'Title';

  @override
  String get amount => 'Amount';

  @override
  String get type => 'Type';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get category => 'Category';

  @override
  String get amountMustBeGreaterThanZero => 'Amount must be greater than 0';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get invalidAmountFormat => 'Invalid amount format';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get lightTheme => 'Light theme';
}
