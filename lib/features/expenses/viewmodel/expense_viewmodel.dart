import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchExpenses(int userId) async {
    _setLoading(true);
    _expenses = await _repository.getExpensesForUser(userId);
    _setLoading(false);
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.addExpense(expense);
    await fetchExpenses(expense.userId);
  }

  Future<void> updateExpense(Expense expense) async {
    await _repository.updateExpense(expense);
    await fetchExpenses(expense.userId);
  }

  Future<void> deleteExpense(int id, int userId) async {
    await _repository.deleteExpense(id);
    await fetchExpenses(userId);
  }
}
