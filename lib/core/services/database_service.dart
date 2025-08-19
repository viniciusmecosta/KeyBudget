import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase('keybudget.db');
    return _database!;
  }

  Future<Database> _initDatabase(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    final dbPassword = dotenv.env['DB_PASSWORD'];

    if (dbPassword == null) {
      throw Exception("DB_PASSWORD not found in .env file");
    }

    return await openDatabase(
      path,
      version: 1,
      password: dbPassword,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        avatar_path TEXT,
        phone_number TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        location TEXT NOT NULL,
        login TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        email TEXT,
        phone_number TEXT,
        notes TEXT,
        logo_path TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }
}
