import 'package:flutter/material.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  int get selectedIndex => _selectedIndex;

  int get previousIndex => _previousIndex;

  set selectedIndex(int index) {
    if (_selectedIndex != index) {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void clearData({bool notify = true}) {
    _selectedIndex = 0;
    _previousIndex = 0;
    if (notify) {
      notifyListeners();
    }
  }
}
