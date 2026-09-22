import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/app/navigation/app_destination.dart';

class NavigationViewModel extends ChangeNotifier {
  AppDestination _currentDestination = AppDestination.dashboard;
  AppDestination _previousDestination = AppDestination.dashboard;
  bool _enableSuppliers = false;
  int _selectionRevision = 0;

  AppDestination get currentDestination => _currentDestination;
  AppDestination get previousDestination => _previousDestination;
  bool get enableSuppliers => _enableSuppliers;
  int get selectionRevision => _selectionRevision;

  int get selectedIndex {
    final available = AppDestination.getAvailable(enableSuppliers: _enableSuppliers);
    final index = available.indexOf(_currentDestination);
    return index >= 0 ? index : 0;
  }

  int get previousIndex {
    final available = AppDestination.getAvailable(enableSuppliers: _enableSuppliers);
    final index = available.indexOf(_previousDestination);
    return index >= 0 ? index : 0;
  }

  set selectedIndex(int index) {
    final available = AppDestination.getAvailable(enableSuppliers: _enableSuppliers);
    if (index >= 0 && index < available.length) {
      navigateTo(available[index]);
    }
  }

  void updateSuppliersAvailability(bool enabled) {
    if (_enableSuppliers == enabled) return;
    _enableSuppliers = enabled;

    if (!enabled && _currentDestination == AppDestination.suppliers) {
      _previousDestination = _currentDestination;
      _currentDestination = AppDestination.dashboard;
      _selectionRevision++;
      notifyListeners();
    }
  }

  void navigateTo(AppDestination destination) {
    if (_currentDestination != destination) {
      _previousDestination = _currentDestination;
      _currentDestination = destination;
      _selectionRevision++;
      notifyListeners();
    }
  }

  void clearData({bool notify = true}) {
    _currentDestination = AppDestination.dashboard;
    _previousDestination = AppDestination.dashboard;
    _enableSuppliers = false;
    _selectionRevision = 0;
    if (notify) {
      notifyListeners();
    }
  }
}

final navigationViewModelProvider = ChangeNotifierProvider<NavigationViewModel>(
  (ref) => NavigationViewModel(),
);
