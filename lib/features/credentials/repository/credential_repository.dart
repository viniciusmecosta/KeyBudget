import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/database_service.dart';

class CredentialRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<int> addCredential(Credential credential) async {
    final db = await _dbService.database;
    return await db.insert('credentials', credential.toMap());
  }

  Future<List<Credential>> getCredentialsForUser(int userId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'credentials',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'location ASC',
    );
    return List.generate(maps.length, (i) {
      return Credential.fromMap(maps[i]);
    });
  }

  Future<int> updateCredential(Credential credential) async {
    final db = await _dbService.database;
    return await db.update(
      'credentials',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<int> deleteCredential(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
