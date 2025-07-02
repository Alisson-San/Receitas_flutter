import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:receitas/screens/auth_screen.dart';
import 'package:receitas/managers/gestor_backup.dart';
import 'package:receitas/repositories/ingredientes_repository.dart';
import 'package:receitas/repositories/instrucoes_repository.dart';
import 'package:receitas/repositories/receita_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:receitas/main.dart'; 

class ConfiguracaoUsuarioScreen extends StatefulWidget {
  const ConfiguracaoUsuarioScreen({super.key});

  @override
  State<ConfiguracaoUsuarioScreen> createState() => _ConfiguracaoUsuarioScreenState();
}

class _ConfiguracaoUsuarioScreenState extends State<ConfiguracaoUsuarioScreen> {
  late BackupManager _backupManager;
  final ReceitaRepository _receitaRepository = ReceitaRepository();
  final IngredientesRepository _ingredientesRepository = IngredientesRepository();
  final InstrucoesRepository _instrucoesRepository = InstrucoesRepository();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _backupManager = BackupManager(
        receitaRepository: _receitaRepository,
        ingredientesRepository: _ingredientesRepository,
        instrucoesRepository: _instrucoesRepository,
        userId: user.uid,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin, // Passa a instância
      );
    } else {
      // Tratar caso onde o usuário não está logado, talvez redirecionar
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Configurações do Usuário')),
        body: Center(child: Text('Usuário não logado.')),
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
              onPressed: () => _backupManager.performLocalBackup(context),
              child: const Text('Backup Agora (Arquivo Local)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _backupManager.performFirebaseBackup(context),
              child: const Text('Backup Agora (Firebase)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _backupManager.restoreFromLocalBackup(context);
                // Após a restauração, talvez queira navegar de volta para a lista de receitas
                // ou recarregar a lista se ainda estiver na mesma tela.
                // Para simplificar, vamos apenas assumir que o usuário navegará de volta.
              },
              child: const Text('Restaurar de Arquivo Local'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _backupManager.restoreFromFirebaseBackup(context);
                // Mesma consideração de navegação/recarregamento.
              },
              child: const Text('Restaurar do Firebase'),
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
            // Futuras opções de agendamento de backup aqui
          ],
        ),
      ),
    );
  }
}