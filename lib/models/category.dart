import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<Category> get defaultCategories => [
    Category(
      id: '1',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    Category(
      id: '2',
      name: 'Transport',
      icon: Icons.directions_car,
      color: Colors.blue,
    ),
    Category(
      id: '3',
      name: 'Shopping',
      icon: Icons.shopping_cart,
      color: Colors.purple,
    ),
    Category(
      id: '4',
      name: 'Bills',
      icon: Icons.receipt,
      color: Colors.red,
    ),
    Category(
      id: '5',
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.pink,
    ),
    Category(
      id: '6',
      name: 'Salary',
      icon: Icons.work,
      color: Colors.green,
    ),
  ];
} 