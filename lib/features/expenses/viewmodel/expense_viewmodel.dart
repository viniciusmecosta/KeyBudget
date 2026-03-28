import 'dart:async';

import 'package:flutter/material.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/notification_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final RecurringExpenseRepository _recurringRepository =
      RecurringExpenseRepository();
  final CsvService _csvService = CsvService();
  final PdfService _pdfService = PdfService();
  final DataImportService _dataImportService = DataImportService();

  List<Expense> _allExpenses = [];
  List<Expense> _currentDisplayItems = [];
  List<RecurringExpense> _recurringExpenses = [];
  bool _isLoading = true;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  List<String> _selectedCategoryIds = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _searchQuery = '';
  bool _searchAllPeriods = false;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _recurringExpensesSubscription;
  bool _isListening = false;

  GlobalKey<SliverAnimatedListState>? _listKey;

  void setListKey(GlobalKey<SliverAnimatedListState> key) {
    _listKey = key;
  }

  List<Expense> get allExpenses => _allExpenses;

  List<Expense> get currentDisplayItems => _currentDisplayItems;

  List<RecurringExpense> get recurringExpenses => _recurringExpenses;

  bool get isLoading => _isLoading;

  bool get isExportingCsv => _isExportingCsv;

  bool get isExportingPdf => _isExportingPdf;

  List<String> get selectedCategoryIds => _selectedCategoryIds;

  DateTime get selectedMonth => _selectedMonth;

  String get searchQuery => _searchQuery;

  bool get searchAllPeriods => _searchAllPeriods;

  List<Expense> get filteredExpenses {
    List<Expense> filtered = List.from(_allExpenses);
    if (_selectedCategoryIds.isNotEmpty) {
      filtered = filtered
          .where((exp) =>
              exp.categoryId != null &&
              _selectedCategoryIds.contains(exp.categoryId))
          .toList();
    }
    return filtered;
  }

  List<Expense> get monthlyFilteredExpenses {
    return filteredExpenses
        .where((exp) =>
            exp.date.year == _selectedMonth.year &&
            exp.date.month == _selectedMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get currentMonthTotal {
    return _currentDisplayItems.fold<double>(
        0.0, (sum, exp) => sum + exp.amount);
  }

  String _sanitize(String input) {
    var text = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    const withDia = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    const withoutDia = 'aaaaaeeeeiiiiooooouuuucn';
    for (int i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    return text;
  }

  void setSearchQuery(String query) {
    _searchQuery = _sanitize(query);
    _updateDisplayList(animate: true);
  }

  void setSearchAllPeriods(bool value) {
    if (_searchAllPeriods != value) {
      _searchAllPeriods = value;
      _updateDisplayList(animate: false);
    }
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    _updateDisplayList(animate: false);
  }

  void setCategoryFilter(List<String> categoryIds) {
    _selectedCategoryIds = categoryIds;
    _updateDisplayList(animate: false);
  }

  void clearFilters() {
    _selectedCategoryIds = [];
    _updateDisplayList(animate: false);
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setExportingCsv(bool value) {
    if (_isExportingCsv != value) {
      _isExportingCsv = value;
      notifyListeners();
    }
  }

  void _setExportingPdf(bool value) {
    if (_isExportingPdf != value) {
      _isExportingPdf = value;
      notifyListeners();
    }
  }

  void listenToExpenses(String userId) {
    if (_isListening) return;
    if (!_isLoading) _setLoading(true);

    _expensesSubscription?.cancel();
    _expensesSubscription =
        _repository.getExpensesStreamForUser(userId).listen((newExpenses) {
      _allExpenses = newExpenses;
      _updateDisplayList(animate: true);
      if (_isLoading) _setLoading(false);
    });

    _recurringExpensesSubscription?.cancel();
    _recurringExpensesSubscription = _recurringRepository
        .getRecurringExpensesStream(userId)
        .listen((recurring) {
      _recurringExpenses = recurring;
      checkAndCreateRecurringInstances(userId);
      notifyListeners();
    });

    _isListening = true;
  }

  void _updateDisplayList({bool animate = true}) {
    List<Expense> newList = _searchAllPeriods
        ? (List.from(filteredExpenses)
          ..sort((a, b) => b.date.compareTo(a.date)))
        : List.from(monthlyFilteredExpenses);

    if (_searchQuery.isNotEmpty) {
      newList.retainWhere((exp) {
        final loc = exp.location != null ? _sanitize(exp.location!) : '';
        final mot = exp.motivation != null ? _sanitize(exp.motivation!) : '';
        return loc.contains(_searchQuery) || mot.contains(_searchQuery);
      });
    }

    if (!animate || _listKey?.currentState == null) {
      _currentDisplayItems = List.from(newList);
      notifyListeners();
      return;
    }

    final oldList = List<Expense>.from(_currentDisplayItems);

    for (var i = oldList.length - 1; i >= 0; i--) {
      final oldItem = oldList[i];
      if (!newList.any((newItem) => newItem.id == oldItem.id)) {
        final indexToRemove =
            _currentDisplayItems.indexWhere((item) => item.id == oldItem.id);
        if (indexToRemove != -1) {
          final removedItem = _currentDisplayItems.removeAt(indexToRemove);
          _listKey?.currentState?.removeItem(
            indexToRemove,
            (context, animation) => AnimatedListItem(
              animation: animation,
              child: ActivityTile(expense: removedItem, index: indexToRemove),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }

    for (var i = 0; i < newList.length; i++) {
      final newItem = newList[i];
      final oldIndex =
          _currentDisplayItems.indexWhere((item) => item.id == newItem.id);

      if (oldIndex == -1) {
        _currentDisplayItems.insert(i, newItem);
        _listKey?.currentState
            ?.insertItem(i, duration: const Duration(milliseconds: 300));
      } else {
        if (_currentDisplayItems[oldIndex] != newItem) {
          _currentDisplayItems[oldIndex] = newItem;
          notifyListeners();
        }
        if (oldIndex != i) {
          final item = _currentDisplayItems.removeAt(oldIndex);
          _currentDisplayItems.insert(i, item);
          notifyListeners();
        }
      }
    }

    if (_currentDisplayItems.length != newList.length) {
      _currentDisplayItems = List.from(newList);
      notifyListeners();
    }
  }

  Future<void> addExpense(String userId, Expense expense) async {
    await _repository.addExpense(userId, expense);
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    await _repository.updateExpense(userId, expense);
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _repository.deleteExpense(userId, expenseId);
  }

  Future<void> addRecurringExpense(
      String userId, RecurringExpense expense) async {
    await _recurringRepository.addRecurringExpense(userId, expense);
  }

  Future<void> updateRecurringExpense(
      String userId, RecurringExpense expense) async {
    await _recurringRepository.updateRecurringExpense(userId, expense);
  }

  Future<void> deleteRecurringExpense(String userId, String expenseId) async {
    await _recurringRepository.deleteRecurringExpense(userId, expenseId);
  }

  Future<void> checkAndCreateRecurringInstances(String userId) async {
    final now = DateTime.now();
    for (final recurring in _recurringExpenses) {
      var currentRecurring = recurring;
      while (true) {
        DateTime nextInstanceDate =
            _calculateNextInstanceDate(currentRecurring);

        if (nextInstanceDate.isAfter(now)) {
          final int notificationId = currentRecurring.id?.hashCode ??
              nextInstanceDate.millisecondsSinceEpoch;
          await NotificationService.scheduleExpenseNotification(
            notificationId,
            'Despesa Recorrente Automática',
            'Lembrete: "${currentRecurring.motivation ?? "Sua despesa"}" já foi registrada para hoje.',
            nextInstanceDate,
          );
          break;
        }

        if (currentRecurring.endDate != null &&
            nextInstanceDate.isAfter(currentRecurring.endDate!)) {
          break;
        }

        final newExpense = Expense(
          amount: currentRecurring.amount,
          date: nextInstanceDate,
          categoryId: currentRecurring.categoryId,
          motivation: currentRecurring.motivation,
          location: currentRecurring.location,
        );

        await addExpense(userId, newExpense);

        final updatedRecurring = RecurringExpense(
          id: currentRecurring.id,
          amount: currentRecurring.amount,
          categoryId: currentRecurring.categoryId,
          motivation: currentRecurring.motivation,
          location: currentRecurring.location,
          frequency: currentRecurring.frequency,
          startDate: currentRecurring.startDate,
          endDate: currentRecurring.endDate,
          dayOfWeek: currentRecurring.dayOfWeek,
          dayOfMonth: currentRecurring.dayOfMonth,
          monthOfYear: currentRecurring.monthOfYear,
          lastInstanceDate: nextInstanceDate,
        );
        await updateRecurringExpense(userId, updatedRecurring);
        currentRecurring = updatedRecurring;
      }
    }
  }

  DateTime _calculateNextInstanceDate(RecurringExpense recurring) {
    if (recurring.lastInstanceDate == null) {
      return recurring.startDate;
    }
    DateTime lastDate = recurring.lastInstanceDate!;
    switch (recurring.frequency) {
      case RecurrenceFrequency.daily:
        return lastDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return lastDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        var year = lastDate.year;
        var month = lastDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        var day = recurring.dayOfMonth ?? lastDate.day;
        var daysInNextMonth = DateTime(year, month + 1, 0).day;
        if (day > daysInNextMonth) {
          day = daysInNextMonth;
        }
        return DateTime(year, month, day);
    }
  }

  Future<bool> exportExpensesToCsv(
      BuildContext context, DateTime? start, DateTime? end) async {
    _setExportingCsv(true);
    try {
      List<Expense> expensesToExport = _allExpenses;
      if (start != null && end != null) {
        expensesToExport = _allExpenses
            .where((exp) =>
                exp.date.isAfter(start.subtract(const Duration(days: 1))) &&
                exp.date.isBefore(end.add(const Duration(days: 1))))
            .toList();
      }
      return await _csvService.exportExpenses(context, expensesToExport);
    } finally {
      _setExportingCsv(false);
    }
  }

  Future<void> exportExpensesToPdf(
      BuildContext context,
      DateTime? start,
      DateTime? end,
      AnalysisViewModel analysisViewModel,
      CategoryViewModel categoryViewModel) async {
    _setExportingPdf(true);
    try {
      List<Expense> expensesToExport = _allExpenses;
      if (start != null && end != null) {
        expensesToExport = _allExpenses
            .where((exp) =>
                exp.date.isAfter(start.subtract(const Duration(days: 1))) &&
                exp.date.isBefore(end.add(const Duration(days: 1))))
            .toList();
      }
      expensesToExport.sort((a, b) => a.date.compareTo(b.date));
      await _pdfService.exportExpensesPdf(
          context, expensesToExport, analysisViewModel, categoryViewModel);
    } finally {
      _setExportingPdf(false);
    }
  }

  Future<int> importExpensesFromCsv(String userId) async {
    final data = await _csvService.importCsv();
    if (data == null) return 0;

    int count = 0;
    for (var row in data) {
      final newExpense = Expense(
        date:
            DateTime.tryParse(row['date']?.toString() ?? '') ?? DateTime.now(),
        amount: double.tryParse(row['amount']?.toString() ?? '0.0') ?? 0.0,
        categoryId: null,
        motivation: row['motivation']?.toString(),
        location: row['location']?.toString(),
      );
      await _repository.addExpense(userId, newExpense);
      count++;
    }
    return count;
  }

  Future<int> importAllExpensesFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importExpensesFromJsons(userId);
    _setLoading(false);
    return count;
  }

  List<String> getUniqueLocationsForCategory(String? categoryId, String query) {
    if (categoryId == null || query.isEmpty) return [];

    final locations = _allExpenses.where((exp) =>
        exp.categoryId == categoryId &&
        exp.location != null &&
        exp.location!.isNotEmpty);

    if (locations.isEmpty) return [];

    final frequencyMap = <String, int>{};
    for (var exp in locations) {
      frequencyMap[exp.location!] = (frequencyMap[exp.location!] ?? 0) + 1;
    }

    final queryLower = query.toLowerCase();
    final filteredLocations = frequencyMap.entries.where((entry) {
      return entry.key
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(queryLower));
    });

    final sortedLocations = filteredLocations.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedLocations.map((e) => e.key).take(3).toList();
  }

  List<String> getUniqueMotivationsForCategory(
      String? categoryId, String query) {
    if (categoryId == null || query.isEmpty) return [];

    final motivations = _allExpenses.where((exp) =>
        exp.categoryId == categoryId &&
        exp.motivation != null &&
        exp.motivation!.isNotEmpty);

    if (motivations.isEmpty) return [];

    final frequencyMap = <String, int>{};
    for (var exp in motivations) {
      frequencyMap[exp.motivation!] = (frequencyMap[exp.motivation!] ?? 0) + 1;
    }

    final queryLower = query.toLowerCase();
    final filteredMotivations = frequencyMap.entries.where((entry) {
      return entry.key
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(queryLower));
    });

    final sortedMotivations = filteredMotivations.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMotivations.map((e) => e.key).take(3).toList();
  }

  void clearData() {
    _expensesSubscription?.cancel();
    _recurringExpensesSubscription?.cancel();
    _allExpenses = [];
    _currentDisplayItems = [];
    _recurringExpenses = [];
    _selectedCategoryIds = [];
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _recurringExpensesSubscription?.cancel();
    super.dispose();
  }
}
