import 'dart:async';
import 'dart:io';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_activity_recognition/models/activity_permission.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:health/health.dart';
import 'package:steps_health/utils/database_helper.dart';

// 1. O Ponto de Entrada (Fora de qualquer classe)
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyMotionHandler());
}

// 2. O Handler (A lógica que corre "escondida")
class MyMotionHandler extends TaskHandler {

  StreamSubscription<Activity>? _activitySubscription;

  String? _currentActivity;
  DateTime? _startTime;
  
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    

    // Iniciamos o stream aqui para que ele viva no processo de background
    _activitySubscription = FlutterActivityRecognition.instance.activityStream
        .handleError((error) => print('Erro no sensor background: $error'))
        .listen((activity) async{
      

      final now  = DateTime.now();
      final String newActivity = activity.type.name;

      // Se a atividade mudou (ex: de STILL para WALKING)
      if (_currentActivity != null && _currentActivity != newActivity) {
        // Grava a sessão que acabou de terminar
        await DbHelper.insertSession(_currentActivity!, _startTime!, now);
        
        // Inicia a nova sessão
        _startTime = now;
        _currentActivity = newActivity;
      }else if (_currentActivity == null) {
        _currentActivity = newActivity;
        _startTime = now;
      }


      // 1. ATUALIZA A NOTIFICAÇÃO EM TEMPO REAL
      FlutterForegroundTask.updateService(
        notificationTitle: 'Monitorização Ativa',
        notificationText: 'Atividade: ${activity.type.name.toUpperCase()}',
      );

      // 2. ENVIA PARA A UI (Caso a app esteja aberta, o ecrã atualiza)
      FlutterForegroundTask.sendDataToMain(activity.toJson());
      
      print('Background activity: ${activity.type.name}');
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Código repetitivo aqui
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _activitySubscription?.cancel();
    print('Serviço destruído');
  }

  
}

// 3. A Classe de Setup (Para usares no Widget)
class ForegroundServiceManager {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'health_monitor_channel',
        channelName: 'Monitorização Ativa',
        channelDescription: 'Este serviço permite monitorizar a sua saúde mental.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.HIGH,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowAutoRestart: true,
      ),
    );
  }

  static Future<void> requestPermissions() async {
  // 1. Notificações
  await FlutterForegroundTask.requestNotificationPermission();

  // 2. Atividade Física (Crucial para o tipo HEALTH)
  // Certifica-te que importas o activity recognition aqui também
  ActivityPermission auth = await FlutterActivityRecognition.instance.checkPermission();
  if (auth != ActivityPermission.GRANTED) {
    await FlutterActivityRecognition.instance.requestPermission();
  }
}

  static Future<ServiceRequestResult> start() {
    return FlutterForegroundTask.startService(
      notificationTitle: 'Bem-estar Ativo',
      notificationText: 'A monitorizar movimento...',
      callback: startCallback,
      serviceTypes: [
      ForegroundServiceTypes.health
    ],
    );
  }
}