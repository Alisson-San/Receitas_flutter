import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receita.dart';

class DatabaseHelper {
  static final String _nomeBancoDeDados = "receitas.db";
  static final int _versaoBancoDeDados = 1;
  static late Database _bancoDeDados;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('receitas.db');
    return _database!;
  }

  inicializar() async {
    String caminhoBanco = join(await getDatabasesPath(), _nomeBancoDeDados);
    _bancoDeDados = await openDatabase(
      caminhoBanco,
      version: _versaoBancoDeDados,
      onCreate: criarBD
    );
  }

  Future criarBD(Database db, int version) async {
  await db.execute('''
      CREATE TABLE receitas (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        dataCriacao TEXT NOT NULL
      )
    ''');

  await db.execute('''
    CREATE TABLE ingredientes (
      id TEXT PRIMARY KEY NOT NULL,
      receitaId TEXT NOT NULL,
      nome TEXT NOT NULL,
      quantidade TEXT NOT NULL,
      FOREIGN KEY (receitaId) REFERENCES receitas (id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE instrucoes (
      id TEXT PRIMARY KEY NOT NULL,
      receitaId TEXT NOT NULL,
      ordem INTEGER NOT NULL,
      descricao TEXT NOT NULL,
      FOREIGN KEY (receitaId) REFERENCES receitas (id) ON DELETE CASCADE
    )
  ''');
  }

  Future<int> inserir(String tabela, Map<String, Object?> valores) async {
    await inicializar();
    return await _bancoDeDados.insert(tabela, valores);
  }

  Future<List<Map<String, Object?>>> obterTodos(String tabela,
      {String? condicao, List<Object>? conidcaoArgs}) async {
    await inicializar();
    return await _bancoDeDados.query(tabela,
        where: condicao, whereArgs: conidcaoArgs);
  }


  Future<int> atualizar(Receita receita) async {
      await inicializar();
    return await _bancoDeDados.update(tabela, valores);
  }

  Future<int> deletar(String tabela, int id) async {
    final db = await instance.database;
    return await db.delete(
      'receitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}