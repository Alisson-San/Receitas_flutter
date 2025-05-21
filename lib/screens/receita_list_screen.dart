import 'package:flutter/material.dart';
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
  ReceitaRepository repositoryReceita = ReceitaRepository();
  IngredientesRepository repositoryIngredientes = IngredientesRepository();
  InstrucoesRepository repositoryInstrucoes = InstrucoesRepository();


  @override
  void initState() {
    super.initState();
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

  void _addReceita() async {
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar Receita'),
      content: const Text('Como você deseja criar a receita?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 1),
          child: const Text('Manual'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 2),
          child: const Text('Aleatória'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );

  if (result == 1) {
    _addManualRecipe();
  } else if (result == 2) {
    _addRandomRecipe();
  }
}

Future<void> _addRandomRecipe() async {
  try {
    final loadingDialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando receita aleatória...'),
          ],
        ),
      ),
    );

    final randomText = await ReceitaService.fetchRandomRecipe();
    final novaReceita = ReceitaService.parseRecipeFromText(randomText);
    final receitaId = Uuid().v1();
    
    // Define o ID da receita
    novaReceita.id = receitaId;
    
    // Salva a receita
    await repositoryReceita.adicionar(novaReceita);
    
    // Salva os ingredientes
    for (var ingrediente in novaReceita.ingredientes) {
      ingrediente.receitaId = receitaId;
      await repositoryIngredientes.adicionar(ingrediente);
    }
    
    // Salva as instruções
    for (var instrucao in novaReceita.instrucoes) {
      instrucao.receitaId = receitaId;
      await repositoryInstrucoes.adicionar(instrucao);
    }
    
    Navigator.pop(context); // Fecha o diálogo de loading
    carregarReceitas();
    
  } catch (e) {
    Navigator.pop(context); // Fecha o diálogo de loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao gerar receita: $e')),
    );
  }
}

Future<void> _addManualRecipe() async {
  final textController = TextEditingController();
  
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar Receita'),
      content: TextField(
        controller: textController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome da Receita'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (textController.text.isNotEmpty) {
              Navigator.pop(context, textController.text);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    ),
  );

  if (result != null && result.isNotEmpty) {
    await repositoryReceita.adicionar(Receita(
      nome: result, 
      id: Uuid().v1(), 
      dataCriacao: DateTime.now().toIso8601String().split('T')[0], 
      ingredientes: [], 
      instrucoes: []
    ));
    carregarReceitas();
  }
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
        onPressed: _addReceita,
        child: Icon(Icons.add),
      ),
    );
  }
}
