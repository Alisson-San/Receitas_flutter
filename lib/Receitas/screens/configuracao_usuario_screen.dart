import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:receitas/screens/auth_screen.dart';
import 'package:receitas/managers/gestor_backup.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/repositories/receita_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:receitas/main.dart' as app_main;
import 'package:workmanager/workmanager.dart';

class ConfiguracaoUsuarioScreen extends StatefulWidget {
  const ConfiguracaoUsuarioScreen({super.key});

  @override
  State<ConfiguracaoUsuarioScreen> createState() => _ConfiguracaoUsuarioScreenState();
}

class _ConfiguracaoUsuarioScreenState extends State<ConfiguracaoUsuarioScreen> {
  late GestorBackup _gestorBackup;

  final ReceitaRepository _receitaRepository = ReceitaRepository();
  final IngredientesRepository _ingredientesRepository = IngredientesRepository();
  final InstrucoesRepository _instrucoesRepository = InstrucoesRepository();

    // Variáveis para agendamento
  String _selectedBackupType = 'local';
  String _selectedInterval = 'none';

  
  final Map<String, Duration> _intervalDurations = {
    'none': Duration.zero,
    '10m': const Duration(minutes: 15),
    '1h': const Duration(hours: 1),
    '1d': const Duration(days: 1),
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _gestorBackup = GestorBackup(
        receitaRepository: _receitaRepository,
        ingredientesRepository: _ingredientesRepository,
        instrucoesRepository: _instrucoesRepository,
        userId: user.uid,
        servicoNotificacao: app_main.notificationService,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }


  // Função para agendar o backup
  void _scheduleBackup() async {
    await Workmanager().cancelByTag('backup_task_tag'); // Cancela qualquer tarefa anterior com esta tag

    if (_selectedInterval == 'none') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup agendado cancelado.')),
      );
      return;
    }

    final Duration frequency = _intervalDurations[_selectedInterval]!;
    final String taskName = '${_selectedBackupType}BackupTask';

    await Workmanager().registerPeriodicTask(
      "backup_task_id", // ID único para a tarefa
      taskName, // Nome da tarefa a ser executada no dispatcher
      tag: 'backup_task_tag', // Tag para cancelar/gerenciar grupos de tarefas
      frequency: frequency,
      initialDelay: const Duration(seconds: 10), // Inicia após 10 segundos para testar
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresCharging: false,
      ),
      inputData: <String, dynamic>{
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'backupType': _selectedBackupType,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup ${_selectedBackupType} agendado a cada ${_selectedInterval}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configurações do Usuário')),
        body: const Center(child: Text('Usuário não logado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações do Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-mail: ${user.email ?? 'Não disponível'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _gestorBackup.performLocalBackup(context),
              child: const Text('Backup Agora (Arquivo Local)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _gestorBackup.performFirebaseBackup(context),
              child: const Text('Backup Agora (Firebase)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _gestorBackup.restoreFromLocalBackup(context);
              },
              child: const Text('Restaurar de Arquivo Local'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _gestorBackup.restoreFromFirebaseBackup(context);
              },
              child: const Text('Restaurar do Firebase'),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const Text('Agendar Backup Automático:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Tipo de Backup
            Row(
              children: [
                const Text('Tipo:'),
                Radio<String>(
                  value: 'local',
                  groupValue: _selectedBackupType,
                  onChanged: (value) {
                    setState(() {
                      _selectedBackupType = value!;
                    });
                  },
                ),
                const Text('Local'),
                Radio<String>(
                  value: 'firebase',
                  groupValue: _selectedBackupType,
                  onChanged: (value) {
                    setState(() {
                      _selectedBackupType = value!;
                    });
                  },
                ),
                const Text('Firebase'),
              ],
            ),

            // Frequência
            DropdownButton<String>(
              value: _selectedInterval,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedInterval = newValue!;
                });
              },
              items: <String>['none', '10m', '1h', '1d']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'none' ? 'Nenhum' : 'A cada $value'),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scheduleBackup,
              child: const Text('Salvar Agendamento'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text('Sair (Logout)'),
            ),
          ],
        ),
      ),
    );
  }
}