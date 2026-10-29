import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:passfin/app/navigation/app_destination.dart';

class NavigationViewModel extends ChangeNotifier {
  AppDestination _currentDestination = AppDestination.dashboard;
  AppDestination _previousDestination = AppDestination.dashboard;
  bool _enableSuppliers = false;
  List<String> _hiddenIds = const [];
  List<String> _order = const [];
  int _selectionRevision = 0;

  AppDestination get currentDestination => _currentDestination;
  AppDestination get previousDestination => _previousDestination;
  bool get enableSuppliers => _enableSuppliers;
  int get selectionRevision => _selectionRevision;

  int get selectedIndex {
    final available = availableDestinations;
    final index = available.indexOf(_currentDestination);
    return index >= 0 ? index : 0;
  }

  int get previousIndex {
    final available = availableDestinations;
    final index = available.indexOf(_previousDestination);
    return index >= 0 ? index : 0;
  }

  set selectedIndex(int index) {
    final available = availableDestinations;
    if (index >= 0 && index < available.length) {
      navigateTo(available[index]);
    }
  }

  void updateSuppliersAvailability(bool enabled) {
    updateAvailability(enableSuppliers: enabled);
  }

  List<AppDestination> get availableDestinations => AppDestination.getAvailable(
    enableSuppliers: _enableSuppliers,
    hiddenIds: _hiddenIds,
    order: _order,
  );

  void updateAvailability({
    required bool enableSuppliers,
    List<String> hiddenIds = const [],
    List<String> order = const [],
  }) {
    if (_enableSuppliers == enableSuppliers &&
        _sameList(_hiddenIds, hiddenIds) &&
        _sameList(_order, order)) {
      return;
    }
    _enableSuppliers = enableSuppliers;
    _hiddenIds = List.of(hiddenIds);
    _order = List.of(order);
    if (!availableDestinations.contains(_currentDestination)) {
      _previousDestination = _currentDestination;
      _currentDestination = availableDestinations.first;
      _selectionRevision++;
    }
    notifyListeners();
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  void navigateTo(AppDestination destination) {
    if (!availableDestinations.contains(destination)) return;
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
    _hiddenIds = const [];
    _order = const [];
    _selectionRevision = 0;
    if (notify) {
      notifyListeners();
    }
  }
}

final navigationViewModelProvider = ChangeNotifierProvider<NavigationViewModel>(
  (ref) => NavigationViewModel(),
);
