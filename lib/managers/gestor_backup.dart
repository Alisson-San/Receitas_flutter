import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:receitas/models/receita.dart';
import 'package:receitas/models/Ingrediente.dart';
import 'package:receitas/models/Instrucao.dart';
import 'package:receitas/repositories/receita_repository.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/services/notificacao_service.dart';

class GestorBackup {
  final ReceitaRepository receitaRepository;
  final IngredientesRepository ingredientesRepository;
  final InstrucoesRepository instrucoesRepository;
  final String userId;
  final ServicoNotificacao servicoNotificacao;

  GestorBackup({
    required this.receitaRepository,
    required this.ingredientesRepository,
    required this.instrucoesRepository,
    required this.userId,
    required this.servicoNotificacao,
  });

  
  Future<List<Receita>> _getAllUserData() async {
    final List<Receita> receitas = await receitaRepository.todosDoUsuario(userId);
    for (var receita in receitas) {
      receita.ingredientes = await ingredientesRepository.todosDaReceita(receita.id!);
      receita.instrucoes = await instrucoesRepository.todosDaReceita(receita.id!);
    }
    return receitas;
  }

  Future<void> performLocalBackup(BuildContext context) async {
    try {
      final List<Receita> allUserData = await _getAllUserData();
      final List<Map<String, dynamic>> jsonData = allUserData.map((r) => r.toJson()).toList();
      final String jsonString = jsonEncode(jsonData);

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        final String fileName = 'receitas_backup_${DateTime.now().toIso8601String().split('.')[0]}.json';
        final File file = File('$selectedDirectory/$fileName');
        await file.writeAsString(jsonString);
        // Chame o serviço de notificação
        servicoNotificacao.mostrarNotificacao('Backup Local Concluído', 'Suas receitas foram salvas em $fileName');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup local salvo em: ${file.path}')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleção de diretório cancelada.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao realizar backup local: $e');
      // Chame o serviço de notificação para erros
      servicoNotificacao.mostrarNotificacao('Erro no Backup Local', 'Falha ao salvar receitas: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao realizar backup local: $e')),
        );
      }
    }
  }

  // --- Backup Firebase (Cloud Firestore) ---
  Future<void> performFirebaseBackup(BuildContext context) async {
    try {
      final List<Receita> allUserData = await _getAllUserData();
      final CollectionReference userRecipesCollection =
          FirebaseFirestore.instance.collection('users').doc(userId).collection('recipes');

      final QuerySnapshot existingRecipes = await userRecipesCollection.get();
      for (DocumentSnapshot doc in existingRecipes.docs) {
        await doc.reference.delete();
      }

      for (var receita in allUserData) {
        await userRecipesCollection.doc(receita.id).set(receita.toJson());
        if (receita.ingredientes.isNotEmpty) {
          final CollectionReference ingredientesSubCollection =
              userRecipesCollection.doc(receita.id).collection('ingredientes');
          for (var ingrediente in receita.ingredientes) {
            await ingredientesSubCollection.doc(ingrediente.id).set(ingrediente.toJson());
          }
        }
        if (receita.instrucoes.isNotEmpty) {
          final CollectionReference instrucoesSubCollection =
              userRecipesCollection.doc(receita.id).collection('instrucoes');
          for (var instrucao in receita.instrucoes) {
            await instrucoesSubCollection.doc(instrucao.id).set(instrucao.toJson());
          }
        }
      }
      // Chame o serviço de notificação
      servicoNotificacao.mostrarNotificacao('Backup Firebase Concluído', 'Suas receitas foram salvas no Firebase.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup no Firebase concluído com sucesso!')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao realizar backup Firebase: $e');
      // Chame o serviço de notificação para erros
      servicoNotificacao.mostrarNotificacao('Erro no Backup Firebase', 'Falha ao salvar receitas: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao realizar backup Firebase: $e')),
        );
      }
    }
  }

  // --- Restauração Local (Arquivo JSON) ---
  Future<void> restoreFromLocalBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<Receita> restoredRecipes = jsonData.map((e) => Receita.fromJson(e)).toList();

        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Restauração'),
            content: const Text(
                'A restauração substituirá todas as suas receitas atuais. Deseja continuar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _clearUserDataInSQLite();

          for (var receita in restoredRecipes) {
            receita.userId = userId;
            await receitaRepository.adicionar(receita);
            for (var ingrediente in receita.ingredientes) {
              ingrediente.receitaId = receita.id;
              await ingredientesRepository.adicionar(ingrediente);
            }
            for (var instrucao in receita.instrucoes) {
              instrucao.receitaId = receita.id;
              await instrucoesRepository.adicionar(instrucao);
            }
          }
          
          servicoNotificacao.mostrarNotificacao('Restauração Local Concluída', 'Receitas restauradas do arquivo.');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restauração do backup local concluída!')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleção de arquivo cancelada.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao restaurar backup local: $e');
      
      servicoNotificacao.mostrarNotificacao('Erro na Restauração Local', 'Falha ao restaurar receitas: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar backup local: $e')),
        );
      }
    }
  }

  
  Future<void> restoreFromFirebaseBackup(BuildContext context) async {
    try {
      final CollectionReference userRecipesCollection =
          FirebaseFirestore.instance.collection('users').doc(userId).collection('recipes');

      final QuerySnapshot recipesSnapshot = await userRecipesCollection.get();
      if (recipesSnapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum backup encontrado no Firebase para este usuário.')),
          );
        }
        return;
      }

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Restauração Firebase'),
          content: const Text(
              'A restauração do Firebase substituirá todas as suas receitas atuais. Deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _clearUserDataInSQLite();

        for (var doc in recipesSnapshot.docs) {
          final Receita receita = Receita.fromJson(doc.data() as Map<String, dynamic>);
          receita.userId = userId;

          final QuerySnapshot ingredientesSnapshot =
              await userRecipesCollection.doc(receita.id).collection('ingredientes').get();
          receita.ingredientes = ingredientesSnapshot.docs
              .map((ingDoc) => Ingrediente.fromJson(ingDoc.data()))
              .toList();

          final QuerySnapshot instrucoesSnapshot =
              await userRecipesCollection.doc(receita.id).collection('instrucoes').get();
          receita.instrucoes = instrucoesSnapshot.docs
              .map((instDoc) => Instrucao.fromJson(instDoc.data()))
              .toList();

          await receitaRepository.adicionar(receita);
          for (var ingrediente in receita.ingredientes) {
            await ingredientesRepository.adicionar(ingrediente);
          }
          for (var instrucao in receita.instrucoes) {
            await instrucoesRepository.adicionar(instrucao);
          }
        }
        servicoNotificacao.mostrarNotificacao('Restauração Firebase Concluída', 'Receitas restauradas do Firebase.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restauração do backup Firebase concluída!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao restaurar backup Firebase: $e');
      servicoNotificacao.mostrarNotificacao('Erro na Restauração Firebase', 'Falha ao restaurar receitas: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar backup Firebase: $e')),
        );
      }
    }
  }


  // --- Método para Limpar Dados do Usuário no SQLite (antes da restauração) ---
  Future<void> _clearUserDataInSQLite() async {
    final List<Receita> userRecipes = await receitaRepository.todosDoUsuario(userId);
    for (var receita in userRecipes) {
      await ingredientesRepository.removerTodosDaReceita(receita.id!);
      await instrucoesRepository.removerTodosDaReceita(receita.id!);
    }
    await receitaRepository.removerTodosDoUsuario(userId);
  }
}