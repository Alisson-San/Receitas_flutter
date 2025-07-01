// lib/utils/recipe_creation_manager.dart
import 'package:flutter/material.dart';
import 'package:receitas/models/receita.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/repositories/receita_repository.dart';
import 'package:receitas/services/receita_service.dart';
import 'package:uuid/uuid.dart';

class ReceitaCriacaoGestor {
  final ReceitaRepository receitaRepository;
  final IngredientesRepository ingredientesRepository;
  final InstrucoesRepository instrucoesRepository;

  ReceitaCriacaoGestor({
    required this.receitaRepository,
    required this.ingredientesRepository,
    required this.instrucoesRepository,
  });

  Future<void> escolherCriacaoReceita(BuildContext context, Function onRecipeAdded) async {
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
      await _addReceitaManual(context);
      onRecipeAdded();
    } else if (result == 2) {
      await _addReceitaGerada(context);
      onRecipeAdded();
    }
  }

  Future<void> _addReceitaGerada(BuildContext context) async {
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
      final receitaId = const Uuid().v1();
      
      novaReceita.id = receitaId;
      
      await receitaRepository.adicionar(novaReceita);
      
      for (var ingrediente in novaReceita.ingredientes) {
        ingrediente.receitaId = receitaId;
        await ingredientesRepository.adicionar(ingrediente);
      }
      
      for (var instrucao in novaReceita.instrucoes) {
        instrucao.receitaId = receitaId;
        await instrucoesRepository.adicionar(instrucao);
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Fecha o diálogo de loading
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha o diálogo de loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar receita: $e')),
        );
      }
    }
  }

  Future<void> _addReceitaManual(BuildContext context) async {
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
      await receitaRepository.adicionar(Receita(
        nome: result, 
        id: const Uuid().v1(), 
        dataCriacao: DateTime.now().toIso8601String().split('T')[0], 
        ingredientes: [], 
        instrucoes: []
      ));
    }
  }
}