// lib/providers/navigation_provider.dart

import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void goToPage(int index) {
    if (index >= 0 && index <= 5) { // sesuaikan dengan jumlah halaman kamu
      _currentIndex = index;
      notifyListeners(); // Memberi tahu widget bahwa state telah berubah
    }
  }
}