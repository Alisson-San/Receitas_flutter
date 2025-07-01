import 'package:flutter/material.dart';
import 'package:receitas/manager/receita_criacao_gestor.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/services/receita_service.dart';
import '/models/receita.dart';
import '/repositories/receita_repository.dart';
import '/screens/receita_detalhe_screen.dart';
import 'package:uuid/uuid.dart';

class ReceitaListScreen extends StatefulWidget {
  const ReceitaListScreen({super.key});

  @override
  _ReceitaListScreenState createState() => _ReceitaListScreenState();
}

class _ReceitaListScreenState extends State<ReceitaListScreen> {
  List<Receita> _receita = [];
  late ReceitaRepository repositoryReceita = ReceitaRepository();
  late IngredientesRepository repositoryIngredientes = IngredientesRepository();
  late InstrucoesRepository repositoryInstrucoes = InstrucoesRepository();
  late ReceitaCriacaoGestor _receitaCriacaoGestor;


  @override
  void initState() {
    super.initState();
    repositoryReceita = ReceitaRepository();
    repositoryIngredientes = IngredientesRepository();
    repositoryInstrucoes = InstrucoesRepository();
    _receitaCriacaoGestor = ReceitaCriacaoGestor( // Inicializa o gestor
      receitaRepository: repositoryReceita,
      ingredientesRepository: repositoryIngredientes,
      instrucoesRepository: repositoryInstrucoes,
    );
    carregarReceitas();
  }

  void carregarReceitas() async {
    var receitaBanco = await repositoryReceita.todos();
    for (var receita in receitaBanco) {
      var ingredientes = await repositoryIngredientes.todosDaReceita(receita.id!);
      var instrucoes = await repositoryInstrucoes.todosDaReceita(receita.id!);
      setState(() {
        receita.ingredientes = ingredientes;
        receita.instrucoes = instrucoes;
      });
    }    
    setState(() {
      _receita = receitaBanco;
    });
  }
  

  String _montarSubtitle(Receita receita) {
    String dataCriacao = receita.dataCriacao ?? '';
    int ingredientes = receita.ingredientes.length;
    int instrucoes = receita.instrucoes.length;
    return 'Criado:$dataCriacao \nIngredientes:$ingredientes \nInstruções:$instrucoes';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receitas'),
      ),
      body: ListView.builder(
          itemCount: _receita.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_receita[index].nome ?? ''),
              subtitle: Text(_montarSubtitle(_receita[index])),
              leading: Icon(Icons.receipt),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceitaDetalheScreen(
                        receita: _receita[index],
                        repositoryReceita: ReceitaRepository(),
                        repositoryIngredientes: IngredientesRepository(),
                        repositoryInstrucoes: InstrucoesRepository()),
                        )
                      );
                carregarReceitas();
                  
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _receitaCriacaoGestor.escolherCriacaoReceita(context, carregarReceitas),
        child: Icon(Icons.add),
      ),
    );
  }
}
