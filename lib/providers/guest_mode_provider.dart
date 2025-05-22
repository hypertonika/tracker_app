import 'package:flutter/material.dart';

class GuestModeProvider with ChangeNotifier {
  bool _isGuest = false;
  bool get isGuest => _isGuest;

  void setGuest(bool value) {
    _isGuest = value;
    notifyListeners();
  }
} 