import 'package:flutter/material.dart';
import 'package:receitas/models/receita.dart';
import 'package:receitas/models/Ingrediente.dart';
import 'package:receitas/models/Instrucao.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/repositories/receita_repository.dart';


class ReceitaDetalheScreen extends StatefulWidget {
  final Receita receita;

  const ReceitaDetalheScreen({super.key, required this.receita});

  @override
  _ReceitaDetalheScreenState createState() => _ReceitaDetalheScreenState();
}

class _ReceitaDetalheScreenState extends State<ReceitaDetalheScreen> {
  late Receita _receitaAtualizada;
  late IngredientesRepository _ingredientesRepository;
  late InstrucoesRepository _instrucoesRepository;
  late ReceitaRepository _receitaRepository;

  @override
  void initState() {
    super.initState();
    _receitaAtualizada = widget.receita;
    _ingredientesRepository = IngredientesRepository();
    _instrucoesRepository = InstrucoesRepository();
    _receitaRepository = ReceitaRepository();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final ingredientes = await _ingredientesRepository.todosDaReceita(_receitaAtualizada.id!);
    final instrucoes = await _instrucoesRepository.todosDaReceita(_receitaAtualizada.id!);
    
    setState(() {
      _receitaAtualizada.ingredientes.addAll(ingredientes);
      _receitaAtualizada.instrucoes.addAll(instrucoes);
    });
  }

  void _adicionarIngrediente() async {
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Ingrediente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do Ingrediente'),
            ),
            TextField(
              controller: quantidadeController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (nomeController.text.isNotEmpty && quantidadeController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final novoIngrediente = Ingrediente(
        receitaId: _receitaAtualizada.id,
        nome: nomeController.text,
        quantidade: quantidadeController.text,
      );
      
      await _ingredientesRepository.adicionar(novoIngrediente);
      _carregarDados();
    }
  }

  void _editarIngrediente(int index) async {
    final ingrediente = _receitaAtualizada.ingredientes[index];
    final nomeController = TextEditingController(text: ingrediente.nome);
    final quantidadeController = TextEditingController(text: ingrediente.quantidade?.toString() ?? '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Ingrediente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do Ingrediente'),
            ),
            TextField(
              controller: quantidadeController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (nomeController.text.isNotEmpty && quantidadeController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final ingredienteAtualizado = Ingrediente(
        id: ingrediente.id,
        receitaId: ingrediente.receitaId,
        nome: nomeController.text,
        quantidade: quantidadeController.text,
      );
      
      await _ingredientesRepository.atualizar(ingredienteAtualizado);
      _carregarDados();
    }
  }

  void _removerIngrediente(int index) async {
    final ingrediente = _receitaAtualizada.ingredientes[index];
    await _ingredientesRepository.remover(ingrediente.id!);
    _carregarDados();
  }

  void _adicionarInstrucao() async {
    final descricaoController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Instrução'),
        content: TextField(
          controller: descricaoController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Descrição da Instrução'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (descricaoController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final novaInstrucao = Instrucao(
        receitaId: _receitaAtualizada.id,
        descricao: descricaoController.text,
        passo: _receitaAtualizada.instrucoes.length + 1,
      );
      
      await _instrucoesRepository.adicionar(novaInstrucao);
      _carregarDados();
    }
  }

  void _editarInstrucao(int index) async {
    final instrucao = _receitaAtualizada.instrucoes[index];
    final descricaoController = TextEditingController(text: instrucao.descricao);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Instrução'),
        content: TextField(
          controller: descricaoController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Descrição da Instrução'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (descricaoController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final instrucaoAtualizada = Instrucao(
        id: instrucao.id,
        receitaId: instrucao.receitaId,
        descricao: descricaoController.text,
        passo: instrucao.passo,
      );
      
      await _instrucoesRepository.atualizar(instrucaoAtualizada);
      _carregarDados();
    }
  }

  void _removerInstrucao(int index) async {
    final instrucao = _receitaAtualizada.instrucoes[index];
    await _instrucoesRepository.remover(instrucao.id!);
    _carregarDados();
  }

  void _editarReceita() async {
  final nomeController = TextEditingController(text: _receitaAtualizada.nome);
  
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar Receita'),
      content: TextField(
        controller: nomeController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome da Receita'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (nomeController.text.isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );

  if (result == true) {
    setState(() {
      _receitaAtualizada.nome = nomeController.text;
    });
    await _receitaRepository.atualizar(_receitaAtualizada);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_receitaAtualizada.nome ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarReceita,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Adicionar lógica para remover a receita
              Navigator.pop(context, true); // Retorna true para indicar que a receita foi removida
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção 1: Informações Básicas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _receitaAtualizada.nome ?? '',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Criada em: ${_receitaAtualizada.dataCriacao?.split('T')[0] ?? ''}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Seção 2: Ingredientes
            Row(
              children: [
                Text(
                  'Ingredientes',
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _adicionarIngrediente,
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _receitaAtualizada.ingredientes.length,
              itemBuilder: (context, index) {
                final ingrediente = _receitaAtualizada.ingredientes[index];
                return ListTile(
                  title: Text('${ingrediente.nome} - ${ingrediente.quantidade}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editarIngrediente(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _removerIngrediente(index),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Seção 3: Modo de Preparo
            Row(
              children: [
                Text(
                  'Modo de Preparo'
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _adicionarInstrucao,
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _receitaAtualizada.instrucoes.length,
              itemBuilder: (context, index) {
                final instrucao = _receitaAtualizada.instrucoes[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    child: Text('${instrucao.passo}'),
                  ),
                  title: Text(instrucao.descricao ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editarInstrucao(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _removerInstrucao(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}