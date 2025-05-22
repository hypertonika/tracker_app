import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as mymodel;

class OfflineStorageService {
  static const String _boxName = 'transactions';
  static const String _syncStatusKey = 'syncStatus';

  Future<void> saveTransactionsLocally(List<mymodel.Transaction> transactions) async {
    final box = await Hive.openBox(_boxName);
    await box.put('transactions', transactions.map((tx) => tx.toJson()).toList());
    await box.put(_syncStatusKey, false);
    await box.close();
  }

  Future<List<mymodel.Transaction>> loadTransactionsLocally() async {
    final box = await Hive.openBox(_boxName);
    final List<dynamic> data = box.get('transactions', defaultValue: []);
    await box.close();
    return data.map((item) => mymodel.Transaction.fromJson(item)).toList();
  }

  Future<bool> isSyncNeeded() async {
    final box = await Hive.openBox(_boxName);
    final bool syncStatus = box.get(_syncStatusKey, defaultValue: true);
    await box.close();
    return !syncStatus;
  }

  Future<void> markAsSynced() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_syncStatusKey, true);
    await box.close();
  }

  Future<void> syncWithFirestore(String userId) async {
    if (!await isSyncNeeded()) return;

    final transactions = await loadTransactionsLocally();
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    for (var tx in transactions) {
      final txRef = userRef.collection('transactions').doc();
      batch.set(txRef, tx.toJson());
    }

    await batch.commit();
    await markAsSynced();
  }
} 