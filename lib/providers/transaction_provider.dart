import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../services/user_prefs_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionProvider with ChangeNotifier {
  final List<Transaction> _transactions = [];
  final List<Budget> _budgets = [];
  final List<Category> _categories = Category.defaultCategories;

  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<Category> get categories => _categories;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
    _saveGuestIfNeeded();
    _saveUserIfNeeded();
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
    _saveGuestIfNeeded();
    _saveUserIfNeeded();
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
    notifyListeners();
  }

  List<Transaction> getTransactionsForMonth(DateTime date) {
    return _transactions.where((t) =>
        t.date.year == date.year && t.date.month == date.month).toList();
  }

  Map<String, double> getCategoryExpenses() {
    final Map<String, double> categoryExpenses = {};
    
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense && transaction.category != null) {
        categoryExpenses[transaction.category!] = 
          (categoryExpenses[transaction.category!] ?? 0) + transaction.amount;
      }
    }
    
    return categoryExpenses;
  }

  void clearAndLoad(List<Transaction> transactions) {
    _transactions.clear();
    _transactions.addAll(transactions);
    notifyListeners();
  }

  Future<void> _saveGuestIfNeeded() async {
    // Сохраняем только если пользователь не авторизован (гостевой режим)
    if (FirebaseAuth.instance.currentUser == null) {
      await UserPrefsService().saveGuestData(_transactions, 'system', 'system');
    }
  }

  Future<void> _saveUserIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await UserPrefsService().saveTransactionsToFirestore(user.uid, _transactions);
    }
  }
} 