import 'package:flutter/material.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void clearData({bool notify = true}) {
    _selectedIndex = 0;
    if (notify) {
      notifyListeners();
    }
  }
}
