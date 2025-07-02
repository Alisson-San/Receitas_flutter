import 'package:receitas/db/database_helper.dart';
import 'package:receitas/models/receita.dart';
import 'package:sqflite/sqflite.dart';

class ReceitaRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> adicionar(Receita receita) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'receitas',
      receita.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizar(Receita receita) async {
    final db = await _databaseHelper.database;
    await db.update(
      'receitas',
      receita.toMap(),
      where: 'id = ?',
      whereArgs: [receita.id],
    );
  }

  Future<void> remover(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'receitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  
  Future<List<Receita>> todosDoUsuario(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receitas',
      where: 'userId = ?', // Filtra pelo userId
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return Receita.fromMap(maps[i]);
    });
  }

  Future<void> removerTodosDoUsuario(String userId) async {
    final db = await _db.database;
    await db.delete(
      'receitas',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}