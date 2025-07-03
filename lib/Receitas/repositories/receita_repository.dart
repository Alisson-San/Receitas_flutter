import 'package:receitas/db/database_helper.dart';
import 'package:receitas/models/receita.dart';
import 'package:sqflite/sqflite.dart';

class ReceitaRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> adicionar(Receita receita) async {
    final db = await _db.database;
    await db.insert(
      'receitas',
      receita.toJson(), 
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizar(Receita receita) async {
    final db = await _db.database;
    await db.update(
      'receitas',
      receita.toJson(),
      where: 'id = ?',
      whereArgs: [receita.id],
    );
  }

  Future<void> remover(String id) async {
    final db = await _db.database;
    await db.delete(
      'receitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Receita>> todosDoUsuario(String userId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receitas',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return Receita.fromJson(maps[i]);
    });
  }

  Future<List<Receita>> todos() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('receitas');
    return List.generate(maps.length, (i) {
      return Receita.fromJson(maps[i]);
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