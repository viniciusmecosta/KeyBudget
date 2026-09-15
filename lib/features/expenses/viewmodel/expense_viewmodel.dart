import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/notification_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/core/time/date_range.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/domain/installment_calculator.dart';
import 'package:key_budget/core/import_export/csv_import_parser.dart';
import 'package:key_budget/core/import_export/import_preview_screen.dart';
import 'package:key_budget/core/import_export/import_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_deletion_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_service.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurrence_occurrence_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;
  final RecurringExpenseRepository _recurringRepository;
  final RecurrenceOccurrenceRepository _occurrenceRepository;
  final RecurrenceService _recurrenceService;
  final RecurrenceDeletionService _recurrenceDeletionService;
  final ImportService _importService;
  final CsvService _csvService;
  final PdfService _pdfService;
  final DataImportService _dataImportService;
  final AppClock _clock;

  ExpenseViewModel({
    ExpenseRepository? repository,
    RecurringExpenseRepository? recurringRepository,
    RecurrenceOccurrenceRepository? occurrenceRepository,
    RecurrenceService? recurrenceService,
    RecurrenceDeletionService? recurrenceDeletionService,
    ImportService? importService,
    CsvService? csvService,
    PdfService? pdfService,
    DataImportService? dataImportService,
    AppClock? clock,
  })  : _repository = repository ?? ExpenseRepository(),
        _recurringRepository =
            recurringRepository ?? RecurringExpenseRepository(),
        _occurrenceRepository =
            occurrenceRepository ?? RecurrenceOccurrenceRepository(),
        _recurrenceService = recurrenceService ??
            RecurrenceService(
              expenseRepository: repository ?? ExpenseRepository(),
              recurringRepository:
                  recurringRepository ?? RecurringExpenseRepository(),
              occurrenceRepository:
                  occurrenceRepository ?? RecurrenceOccurrenceRepository(),
              clock: clock ?? const SystemAppClock(),
            ),
        _recurrenceDeletionService = recurrenceDeletionService ??
            RecurrenceDeletionService(
              recurringRepository:
                  recurringRepository ?? RecurringExpenseRepository(),
              expenseRepository: repository ?? ExpenseRepository(),
              occurrenceRepository:
                  occurrenceRepository ?? RecurrenceOccurrenceRepository(),
              clock: clock ?? const SystemAppClock(),
            ),
        _importService = importService ??
            ImportService(
              expenseRepository: repository ?? ExpenseRepository(),
              credentialRepository: CredentialRepository(),
              recurringRepository:
                  recurringRepository ?? RecurringExpenseRepository(),
            ),
        _csvService = csvService ?? CsvService(),
        _pdfService = pdfService ?? PdfService(),
        _dataImportService = dataImportService ?? DataImportService(),
        _clock = clock ?? const SystemAppClock() {
    final now = _clock.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<Expense> _allExpenses = [];
  List<Expense> _currentDisplayItems = [];
  List<RecurringExpense> _recurringExpenses = [];
  bool _isLoading = true;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  bool _isImportingCsv = false;
  List<String> _selectedCategoryIds = [];
  bool? _filterIsIncome;
  late DateTime _selectedMonth;
  String _searchQuery = '';
  bool _searchAllPeriods = false;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _recurringExpensesSubscription;
  bool _isListening = false;
  bool _enableIncomes = false;

  @Deprecated('UI animation state belongs to presentation layer')
  void setListKey(GlobalKey<SliverAnimatedListState>? key) {

  }

  List<Expense> get allExpenses => _allExpenses;

  @visibleForTesting
  set allExpenses(List<Expense> expenses) {
    _allExpenses = expenses;
    notifyListeners();
  }

  List<Expense> get currentDisplayItems => _currentDisplayItems;

  List<RecurringExpense> get recurringExpenses => _recurringExpenses;

  bool get isLoading => _isLoading;

  bool get isExportingCsv => _isExportingCsv;

  bool get isExportingPdf => _isExportingPdf;

  bool get isImportingCsv => _isImportingCsv;

  ImportService get importService => _importService;

  List<String> get selectedCategoryIds => _selectedCategoryIds;

  bool? get filterIsIncome => _filterIsIncome;

  DateTime get selectedMonth => _selectedMonth;

  String get searchQuery => _searchQuery;

  bool get searchAllPeriods => _searchAllPeriods;

  List<Expense> get filteredExpenses {
    List<Expense> filtered = List.from(_allExpenses);
    if (_filterIsIncome != null) {
      filtered = filtered
          .where((exp) => (exp.isIncome ?? false) == _filterIsIncome)
          .toList();
    }
    if (_selectedCategoryIds.isNotEmpty) {
      filtered = filtered
          .where(
            (exp) =>
                exp.categoryId != null &&
                _selectedCategoryIds.contains(exp.categoryId),
          )
          .toList();
    }
    return filtered;
  }

  List<Expense> get monthlyFilteredExpenses {
    return filteredExpenses
        .where(
          (exp) =>
              exp.date.year == _selectedMonth.year &&
              exp.date.month == _selectedMonth.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get currentMonthTotal {
    List<Expense> baseList = _searchAllPeriods
        ? filteredExpenses
        : monthlyFilteredExpenses;
    if (_searchQuery.isNotEmpty) {
      baseList = baseList.where((exp) {
        final loc = exp.location != null ? _sanitize(exp.location!) : '';
        final mot = exp.motivation != null ? _sanitize(exp.motivation!) : '';
        return loc.contains(_searchQuery) || mot.contains(_searchQuery);
      }).toList();
    }
    return baseList
        .where((e) => e.isIncome != true)
        .fold<double>(0.0, (sum, exp) => sum + exp.amount);
  }

  double get currentMonthIncomeTotal {
    List<Expense> baseList = _searchAllPeriods
        ? filteredExpenses
        : monthlyFilteredExpenses;
    if (_searchQuery.isNotEmpty) {
      baseList = baseList.where((exp) {
        final loc = exp.location != null ? _sanitize(exp.location!) : '';
        final mot = exp.motivation != null ? _sanitize(exp.motivation!) : '';
        return loc.contains(_searchQuery) || mot.contains(_searchQuery);
      }).toList();
    }
    return baseList
        .where((e) => e.isIncome == true)
        .fold<double>(0.0, (sum, exp) => sum + exp.amount);
  }

  double get currentMonthBalance {
    return currentMonthIncomeTotal - currentMonthTotal;
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
    _updateDisplayList(animate: true);
  }

  void setTypeFilter(bool? isIncome) {
    _filterIsIncome = isIncome;
    _updateDisplayList(animate: true);
  }

  void clearFilters() {
    _selectedCategoryIds = [];
    _filterIsIncome = null;
    _updateDisplayList(animate: true);
  }

  void setEnableIncomes(bool value) {
    if (_enableIncomes != value) {
      _enableIncomes = value;

      Future.microtask(() => _updateDisplayList(animate: false));
    }
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

  void _setImportingCsv(bool value) {
    if (_isImportingCsv != value) {
      _isImportingCsv = value;
      notifyListeners();
    }
  }

  void listenToExpenses(String userId) {
    if (_isListening) return;
    if (!_isLoading) _setLoading(true);

    _expensesSubscription?.cancel();
    _expensesSubscription = _repository.getExpensesStreamForUser(userId).listen(
      (newExpenses) {
        _allExpenses = newExpenses;
        _updateDisplayList(animate: true);
        if (_isLoading) _setLoading(false);
      },
    );

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

    if (!_enableIncomes) {
      newList.retainWhere((exp) => exp.isIncome != true);
    }

    _currentDisplayItems = List.unmodifiable(newList);
    notifyListeners();
  }

  Future<void> addExpense(String userId, Expense expense) async {
    final Expense effectiveExpense;
    if (expense.amountMinor == null) {
      final m = Money.fromNumWithHalfAwayFromZero(expense.amount);
      effectiveExpense = expense.copyWith(
        amountMinor: m.amountMinor,
        currency: 'BRL',
        moneyVersion: 1,
      );
    } else {
      effectiveExpense = expense;
    }
    await _repository.addExpense(userId, effectiveExpense);
  }

  Future<void> restoreExpense(String userId, Expense expense) async {
    await _repository.restoreExpense(userId, expense);
    if (expense.recurringExpenseId != null &&
        expense.recurringExpenseId!.isNotEmpty) {
      final dateKey = RecurrenceOccurrence.formatDateKey(expense.date);
      final occurrenceKey = RecurrenceOccurrence.generateKey(
        uid: userId,
        recurringExpenseId: expense.recurringExpenseId!,
        scheduledDateKey: dateKey,
      );
      final occurrence = RecurrenceOccurrence(
        occurrenceKey: occurrenceKey,
        recurringExpenseId: expense.recurringExpenseId!,
        scheduledDateKey: dateKey,
        scheduledDateOriginal: expense.date,
        expenseIds: [if (expense.id != null) expense.id!],
        state: OccurrenceState.materialized,
        engineVersion: 1,
      );
      await _occurrenceRepository.saveOccurrence(userId, occurrence);
    }
  }

  Future<OperationResult<List<Expense>>> addInstallmentExpenses(
    String userId,
    Expense baseExpense,
    int installments,
    bool startNextMonth, {
    String? operationId,
  }) async {
    try {
      final calculation = InstallmentCalculator.calculate(
        baseExpense: baseExpense,
        count: installments,
        startNextMonth: startNextMonth,
        operationId: operationId,
      );

      await _repository.addExpensesBatch(userId, calculation.expenses);

      return OperationResult.completed(
        data: calculation.expenses,
        count: calculation.expenses.length,
        affectedIds: calculation.expenses.map((e) => e.id ?? '').toList(),
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Falha ao gerar parcelas: ${e.toString()}',
      );
    }
  }

  List<Expense> getRelatedInstallments(String groupId) {
    final list = _allExpenses
        .where((e) => e.installmentGroupId == groupId)
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    await _repository.updateExpense(userId, expense);
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    final expense = _allExpenses.firstWhere(
      (e) => e.id == expenseId,
      orElse: () => Expense(
        id: expenseId,
        amount: 0,
        date: DateTime.now(),
      ),
    );
    if (expense.recurringExpenseId != null &&
        expense.recurringExpenseId!.isNotEmpty) {
      await _recurrenceDeletionService.deleteIndividualOccurrence(
        userId: userId,
        expense: expense,
      );
    } else {
      await _repository.deleteExpense(userId, expenseId);
    }
  }

  Future<void> deleteInstallmentGroup(String userId, String groupId) async {
    final expensesToDelete = _allExpenses
        .where((expense) => expense.installmentGroupId == groupId)
        .toList();

    final futures = expensesToDelete.map((expense) {
      if (expense.id != null) {
        return deleteExpense(userId, expense.id!);
      }
      return Future.value();
    });
    await Future.wait(futures);
  }

  Future<void> addRecurringExpense(
    String userId,
    RecurringExpense expense,
  ) async {
    final RecurringExpense effectiveExpense;
    if (expense.amountMinor == null) {
      final m = Money.fromNumWithHalfAwayFromZero(expense.amount);
      effectiveExpense = expense.copyWith(
        amountMinor: m.amountMinor,
        currency: 'BRL',
        moneyVersion: 1,
      );
    } else {
      effectiveExpense = expense;
    }
    await _recurringRepository.addRecurringExpense(userId, effectiveExpense);
  }

  Future<void> updateRecurringExpense(
    String userId,
    RecurringExpense expense,
  ) async {
    await _recurringRepository.updateRecurringExpense(userId, expense);
  }

  Future<RecurringDeleteSnapshot?> deleteRecurringExpense(
    String userId,
    String expenseId, {
    int deleteMode = 0,
    RecurrenceDeleteMode? mode,
  }) async {
    final effectiveMode = mode ??
        (deleteMode == 1
            ? RecurrenceDeleteMode.futureOnly
            : deleteMode == 2
                ? RecurrenceDeleteMode.all
                : RecurrenceDeleteMode.onlyRule);

    final rule = _recurringExpenses.firstWhere(
      (r) => r.id == expenseId,
      orElse: () => RecurringExpense(
        id: expenseId,
        amount: 0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime.now(),
      ),
    );

    final result = await _recurrenceDeletionService.deleteRule(
      userId: userId,
      rule: rule,
      mode: effectiveMode,
      allExpenses: _allExpenses,
    );

    return result.data;
  }

  Future<void> undoDeleteRecurringExpense(
    String userId,
    RecurringDeleteSnapshot snapshot,
  ) async {
    await _recurrenceDeletionService.undoDelete(
      userId: userId,
      snapshot: snapshot,
    );
  }

  Future<void> restoreRecurringExpense(
    String userId,
    RecurringExpense expense,
  ) async {
    await _recurringRepository.restoreRecurringExpense(userId, expense);
  }

  bool _isGeneratingRecurring = false;

  Future<void> checkAndCreateRecurringInstances(String userId) async {
    if (_isGeneratingRecurring) return;
    _isGeneratingRecurring = true;

    try {
      final result = await _recurrenceService.generatePendingOccurrences(
        userId,
        rulesToProcess: _recurringExpenses,
      );

      if (result.isSuccess) {
        await NotificationService.reconciler.reconcile(
          uid: userId,
          activeRules: _recurringExpenses,
        );
      }
    } finally {
      _isGeneratingRecurring = false;
    }
  }

  Future<bool> exportExpensesToCsv(
    BuildContext context,
    DateTime? start,
    DateTime? end,
  ) async {
    _setExportingCsv(true);
    try {
      List<Expense> expensesToExport;
      if (start != null && end != null) {
        final range = DateRange.fromDays(start, end);
        expensesToExport = _allExpenses
            .where((exp) => range.contains(exp.date))
            .toList();
      } else if (start == null && end == null) {
        expensesToExport = List<Expense>.from(_allExpenses);
      } else {
        return false;
      }
      expensesToExport.sort((a, b) => a.date.compareTo(b.date));
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
    CategoryViewModel categoryViewModel,
  ) async {
    _setExportingPdf(true);
    try {
      List<Expense> expensesToExport;
      if (start != null && end != null) {
        final range = DateRange.fromDays(start, end);
        expensesToExport = _allExpenses
            .where((exp) => range.contains(exp.date))
            .toList();
      } else if (start == null && end == null) {
        expensesToExport = List<Expense>.from(_allExpenses);
      } else {
        return;
      }
      expensesToExport.sort((a, b) => a.date.compareTo(b.date));
      await _pdfService.exportExpensesPdf(
        context,
        expensesToExport,
        analysisViewModel,
        categoryViewModel,
      );
    } finally {
      _setExportingPdf(false);
    }
  }

  Future<int> importExpensesFromCsv(
    String userId, {
    BuildContext? context,
    String? rawCsvContent,
    String? fileName,
  }) async {
    _setImportingCsv(true);
    try {
      String? content = rawCsvContent;
      String name = fileName ?? 'expenses.csv';

      if (content == null) {
        final file = await _csvService.pickCsvFile();
        if (file == null) return 0;
        name = file.path.split('/').last;
        content = await file.readAsString();
      }

      final plan = await _importService.preparePlan(
        userId: userId,
        fileContent: content,
        fileName: name,
        forcedType: CsvImportType.expenses,
        existingExpenses: _allExpenses,
      );

      if (!plan.canProceed) {
        if (context != null && context.mounted) {
          SnackbarService.showError(
            context,
            plan.globalErrors.isNotEmpty
                ? plan.globalErrors.first
                : 'O arquivo CSV não possui registros válidos para importar.',
          );
        }
        return 0;
      }

      if (context != null && context.mounted) {
        final resultCount = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder: (_) => ImportPreviewScreen(
              userId: userId,
              plan: plan,
              importService: _importService,
            ),
          ),
        );
        return resultCount ?? 0;
      } else {
        final result = await _importService.applyPlan(
          userId: userId,
          plan: plan,
          importOnlyValid: true,
        );
        return result.data?.createdCount ?? 0;
      }
    } finally {
      _setImportingCsv(false);
    }
  }

  Future<int> importAllExpensesFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importExpensesFromJsons(userId);
    _setLoading(false);
    return count;
  }

  List<String> getUniqueLocationsForCategory(String? categoryId, String query) {
    if (categoryId == null || query.isEmpty) return [];

    final locations = _allExpenses.where(
      (exp) =>
          exp.categoryId == categoryId &&
          exp.location != null &&
          exp.location!.isNotEmpty,
    );

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

  List<String> getUniqueLocationsForIncome(String query) {
    if (query.isEmpty) return [];

    final locations = _allExpenses.where(
      (exp) =>
          exp.isIncome == true &&
          exp.location != null &&
          exp.location!.isNotEmpty,
    );

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
    String? categoryId,
    String query,
  ) {
    if (categoryId == null || query.isEmpty) return [];

    final motivations = _allExpenses.where(
      (exp) =>
          exp.categoryId == categoryId &&
          exp.motivation != null &&
          exp.motivation!.isNotEmpty,
    );

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

  List<String> getUniqueMotivationsForIncome(String query) {
    if (query.isEmpty) return [];

    final motivations = _allExpenses.where(
      (exp) =>
          exp.isIncome == true &&
          exp.motivation != null &&
          exp.motivation!.isNotEmpty,
    );

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

final recurrenceServiceProvider = Provider<RecurrenceService>((ref) {
  return RecurrenceService(
    expenseRepository: ref.read(expenseRepositoryProvider),
    recurringRepository: ref.read(recurringExpenseRepositoryProvider),
    occurrenceRepository: ref.read(recurrenceOccurrenceRepositoryProvider),
  );
});

final recurrenceDeletionServiceProvider =
    Provider<RecurrenceDeletionService>((ref) {
  return RecurrenceDeletionService(
    recurringRepository: ref.read(recurringExpenseRepositoryProvider),
    expenseRepository: ref.read(expenseRepositoryProvider),
    occurrenceRepository: ref.read(recurrenceOccurrenceRepositoryProvider),
  );
});

final expenseViewModelProvider = ChangeNotifierProvider<ExpenseViewModel>(
  (ref) => ExpenseViewModel(
    repository: ref.read(expenseRepositoryProvider),
    recurringRepository: ref.read(recurringExpenseRepositoryProvider),
    occurrenceRepository: ref.read(recurrenceOccurrenceRepositoryProvider),
    recurrenceService: ref.read(recurrenceServiceProvider),
    recurrenceDeletionService: ref.read(recurrenceDeletionServiceProvider),
    importService: ref.read(importServiceProvider),
    dataImportService: DataImportService(
      expenseRepository: ref.read(expenseRepositoryProvider),
    ),
  ),
);
