import 'package:sqflite/sqflite.dart';
import '../models/receita.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('receitas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        creationDate TEXT NOT NULL
      )
    ''');
  }

  // CRUD Operations
  Future<int> createRecipe(Receita recipe) async {
    final db = await instance.database;
    return await db.insert('receitas', recipe.toMap());
  }

  Future<List<Receita>> readAllRecipes() async {
    final db = await instance.database;
    final result = await db.query('receitas');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<int> updateRecipe(Receita recipe) async {
    final db = await instance.database;
    return await db.update(
      'receitas',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return await db.delete(
      'receitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}