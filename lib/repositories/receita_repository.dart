import '/db/database_helper.dart';
import '/models/receita.dart';

class ReceitaRepository {

  static final DatabaseHelper _db = DatabaseHelper();

  static const String _tabela = "receitas";

  Future<int> adicionar(Receita receita) async {
    return _db.inserir(_tabela, receita.toMap());
  }

  Future<int> atualizar(Receita receita) async {
    return _db.atualizar(_tabela, receita.toMap());
  }

  Future<int> remover(String id) async {
    return _db.deletar(_tabela, {'id': id});
  }
  Future<List<Receita>> todos() async {
    var receitasNoBanco = await _db.obterTodos(_tabela);
    List<Receita> listaDeReceitas = [];

    for (var i = 0; i < receitasNoBanco.length; i++) {
      listaDeReceitas.add(Receita.fromMap(receitasNoBanco[i]));
    }

    return listaDeReceitas;
  }

}