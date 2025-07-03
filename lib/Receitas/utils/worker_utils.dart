import 'dart:convert';
import 'dart:io';
import 'package:receitas/managers/gestor_backup.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart'; 

import 'package:receitas/models/receita.dart';
import 'package:receitas/models/Ingrediente.dart';
import 'package:receitas/models/Instrucao.dart';
import 'package:receitas/repositories/receita_repository.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/services/notificacao_service.dart';

FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
ServicoNotificacao? _backgroundNotificationService;
// Esta função é o ponto de entrada para a execução em segundo plano
@pragma('vm:entry-point') // Essencial para o Workmanager
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint("Native called background task: $taskName");

    try {
      

      if (_backgroundNotificationService == null) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('app_icon');
        
        final InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid
          );
        await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {},
        );
        _backgroundNotificationService = ServicoNotificacao(flutterLocalNotificationsPlugin: _flutterLocalNotificationsPlugin);
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _backgroundNotificationService?.mostrarNotificacao(
            'Backup Agendado Falhou', 'Usuário não logado. Faça login para backups.');
        debugPrint("Workmanager: Usuário não logado para backup agendado.");
        return Future.value(false); // Indica falha
      }
      String userId = user.uid;

      final ReceitaRepository receitaRepository = ReceitaRepository();
      final IngredientesRepository ingredientesRepository = IngredientesRepository();
      final InstrucoesRepository instrucoesRepository = InstrucoesRepository();

      final GestorBackup backupManager = GestorBackup(
        receitaRepository: receitaRepository,
        ingredientesRepository: ingredientesRepository,
        instrucoesRepository: instrucoesRepository,
        userId: userId,
        servicoNotificacao: _backgroundNotificationService!, 
      );

      
      switch (taskName) {
        case "localBackupTask":
          debugPrint("Workmanager: Executando backup local.");
                    await _performLocalBackupInBackground(backupManager, userId);
          break;
        case "firebaseBackupTask":
          debugPrint("Workmanager: Executando backup Firebase.");

          await _performFirebaseBackupInBackground(backupManager);
          break;
        default:
          debugPrint("Workmanager: Tarefa desconhecida: $taskName");
          _backgroundNotificationService?.mostrarNotificacao(
              'Backup Agendado - Erro', 'Tarefa desconhecida: $taskName');
          return Future.value(false); // Indica falha
      }

      return Future.value(true); // Indica sucesso
    } catch (e) {
      debugPrint("Workmanager: Erro na execução da tarefa: $e");
      _backgroundNotificationService?.mostrarNotificacao(
          'Backup Agendado - Erro Crítico', 'Falha na execução da tarefa: $e');
      return Future.value(false); // Indica falha
    }
  });
}

Future<void> _performLocalBackupInBackground(GestorBackup gestorBackup, String userId) async {
  try {
    final List<Receita> allUserData = await gestorBackup._getAllUserData();
    final List<Map<String, dynamic>> jsonData = allUserData.map((r) => r.toJson()).toList();
    final String jsonString = jsonEncode(jsonData);

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String backupPath = '${appDocDir.path}/backups_receitas';
    final Directory backupDir = Directory(backupPath);
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final String fileName = 'receitas_backup_auto_${DateTime.now().toIso8601String().split('.')[0]}.json';
    final File file = File('$backupPath/$fileName');
    await file.writeAsString(jsonString);

    _backgroundNotificationService?.mostrarNotificacao('Backup Local Agendado Concluído', 'Suas receitas foram salvas em $fileName');
  } catch (e) {
    debugPrint('Erro no backup local em background: $e');
    _backgroundNotificationService?.mostrarNotificacao('Erro no Backup Local Agendado', 'Falha ao salvar receitas: $e');
    rethrow; 
  }
}

Future<void> _performFirebaseBackupInBackground(GestorBackup gestorBackup) async {
  try {
    final List<Receita> allUserData = await gestorBackup._getAllUserData(); // Acessando método privado
    final CollectionReference userRecipesCollection =
        FirebaseFirestore.instance.collection('users').doc(gestorBackup.userId).collection('recipes');

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
    _backgroundNotificationService?.mostrarNotificacao('Backup Firebase Agendado Concluído', 'Suas receitas foram salvas no Firebase.');
  } catch (e) {
    debugPrint('Erro no backup Firebase em background: $e');
    _backgroundNotificationService?.mostrarNotificacao('Erro no Backup Firebase Agendado', 'Falha ao salvar receitas: $e');
    rethrow; 
  }
}


extension on GestorBackup {
  Future<List<Receita>> _getAllUserData() {
    return this.receitaRepository.todosDoUsuario(this.userId).then((receitas) async {
      for (var receita in receitas) {
        receita.ingredientes = await this.ingredientesRepository.todosDaReceita(receita.id!);
        receita.instrucoes = await this.instrucoesRepository.todosDaReceita(receita.id!);
      }
      return receitas;
    });
  }
}