import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:receitas/firebase_options.dart';
import 'package:receitas/screens/auth_screen.dart';
import 'package:receitas/screens/receita_list_screen.dart';
import 'package:receitas/services/notificacao_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:receitas/utils/worker_utils.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late ServicoNotificacao notificationService; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicialização do plugin de notificações
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      // Lidar com a resposta da notificação (clique)
    },
  );

  // Inicialize o NotificationService APÓS o flutterLocalNotificationsPlugin
  notificationService = ServicoNotificacao(
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minhas Receitas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const ReceitaListScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}