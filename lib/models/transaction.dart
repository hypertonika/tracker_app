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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.toString().split('.').last,
    'category': category,
    'description': description,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    title: json['title'],
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    category: json['category'],
    description: json['description'],
  );
} 