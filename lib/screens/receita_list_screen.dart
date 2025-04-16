import 'package:flutter/material.dart';
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
  ReceitaRepository repository = ReceitaRepository();

  @override
  void initState() {
    super.initState();
    carregarReceitas();
  }

  void carregarReceitas() async {
    var receitaBanco = await repository.todos();
    setState(() {
      _receita = receitaBanco;
    });
  }

  void _addReceita() async {
      final textController = TextEditingController();
      
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Adicionar Recita'),
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
        setState(() {
          repository.adicionar(Receita(nome: result, id: Uuid().v1(), dataCriacao: DateTime.now().toIso8601String().split('T')[0], ingredientes: [], instrucoes: []));
          carregarReceitas();
        });
      }
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
              subtitle: Text(_receita[index].dataCriacao ?? ''),
              leading: Icon(Icons.receipt),
              onTap: () async {
                final receitaRemovida = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceitaDetalheScreen(receita: _receita[index]),
                    ),
                  );
                  
                  if (receitaRemovida == true) {
                    carregarReceitas();
                  }
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
