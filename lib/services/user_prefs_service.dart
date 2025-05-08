import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart' as mymodel;
import 'dart:convert';

class UserPrefsService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> savePrefs(String theme, String language) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'theme': theme,
      'language': language,
    }, SetOptions(merge: true));
  }

  Future<Map<String, String>?> loadPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return {
      'theme': data?['theme'] ?? 'system',
      'language': data?['language'] ?? 'system',
    };
  }

  // --- Guest mode local storage ---
  Future<void> saveGuestData(List<mymodel.Transaction> transactions, String theme, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final txJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString('guest_transactions', jsonEncode(txJson));
    await prefs.setString('guest_theme', theme);
    await prefs.setString('guest_language', language);
  }

  Future<Map<String, dynamic>> loadGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    final txStr = prefs.getString('guest_transactions');
    final theme = prefs.getString('guest_theme') ?? 'system';
    final language = prefs.getString('guest_language') ?? 'system';
    List<mymodel.Transaction> transactions = [];
    if (txStr != null) {
      final txList = jsonDecode(txStr) as List;
      transactions = txList.map((e) => mymodel.Transaction.fromJson(e)).toList();
    }
    return {
      'transactions': transactions,
      'theme': theme,
      'language': language,
    };
  }

  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_transactions');
    await prefs.remove('guest_theme');
    await prefs.remove('guest_language');
  }

  // --- Firestore user transactions ---
  Future<void> saveTransactionsToFirestore(String uid, List<mymodel.Transaction> transactions) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(uid);
    final txRef = userRef.collection('transactions');
    // Удаляем старые транзакции
    final old = await txRef.get();
    for (final doc in old.docs) {
      batch.delete(doc.reference);
    }
    // Добавляем новые
    for (final t in transactions) {
      batch.set(txRef.doc(t.id), t.toJson());
    }
    await batch.commit();
  }

  Future<List<mymodel.Transaction>> loadTransactionsFromFirestore(String uid) async {
    final txRef = _firestore.collection('users').doc(uid).collection('transactions');
    final snap = await txRef.get();
    return snap.docs.map((doc) => mymodel.Transaction.fromJson(doc.data())).toList();
  }
} 