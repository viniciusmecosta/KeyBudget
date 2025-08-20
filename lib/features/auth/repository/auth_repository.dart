import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/services/database_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class AuthRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<User> register(User user) async {
    final db = await _dbService.database;
    final id = await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return User(
      id: id,
      name: user.name,
      email: user.email,
      passwordHash: user.passwordHash,
      avatarPath: user.avatarPath,
      phoneNumber: user.phoneNumber,
    );
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await _dbService.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
