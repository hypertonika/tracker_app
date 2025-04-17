import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? category;
  final String? description;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.category,
    this.description,
  });

  Color get color => type == TransactionType.income ? Colors.green : Colors.red;
  IconData get icon => type == TransactionType.income ? Icons.add : Icons.remove;
} 