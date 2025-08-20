import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/database_service.dart';

class ExpenseRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<int> addExpense(Expense expense) async {
    final db = await _dbService.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpensesForUser(int userId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await _dbService.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
