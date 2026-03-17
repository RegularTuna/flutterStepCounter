import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_activity_recognition/models/activity_permission.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:steps_health/utils/foreground_impl.dart';

class MotionDetection extends StatefulWidget {
  @override
  _MotionDetectionState createState() => _MotionDetectionState();
}

class _MotionDetectionState extends State<MotionDetection> {

  Activity? _activity;


  Future<bool> _checkAndRequestPermission() async {
  ActivityPermission permission =
      await FlutterActivityRecognition.instance.checkPermission();
  if (permission == ActivityPermission.PERMANENTLY_DENIED) {
    // permission has been permanently denied.
    return false;
  } else if (permission == ActivityPermission.DENIED) {
    permission =
        await FlutterActivityRecognition.instance.requestPermission();
    if (permission != ActivityPermission.GRANTED) {
      // permission is denied.
      return false;  
    }
  }

  return true;
}

StreamSubscription<Activity>? _activitySubscription;

Future<void> _subscribeActivityStream() async {
  if (await _checkAndRequestPermission()) {
    _activitySubscription = FlutterActivityRecognition.instance.activityStream
        .handleError(_onError)
        .listen(_onActivity);
  }
}

void _onActivity(Activity activity) {
  print('activity detected >> ${activity.toJson()}');
  setState(() {
    _activity = activity;
  });
}

void _onError(dynamic error) {
  print('error >> $error');
}



  @override
  void initState() {
    super.initState();
    
    // 1. Configura o serviço
    ForegroundServiceManager.init();

    // 2. Ouve os dados que vêm do background (MyMotionHandler)
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map<String, dynamic>) {
        print("UI recebeu: ${data['type']}");
        
        setState(() {
          // Criamos um novo objeto Activity para que o widget reconheça a mudança
          _activity = Activity(
            ActivityType.values.firstWhere((e) => e.name == data['type']),
            ActivityConfidence.values.firstWhere((e) => e.name == data['confidence']),
          );
        });
      }
    });
    // 3. Pede permissões e arranca (após o frame ser desenhado)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ForegroundServiceManager.requestPermissions();
      await ForegroundServiceManager.start();

      
    });
  }

  @override
  Widget build(BuildContext context) {
    final String activityName = _activity?.type.name.toUpperCase() ?? "RETRIEVING...";
    return Scaffold(
      appBar: AppBar(title: Text("Health Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Current Status:", style: TextStyle(color: Colors.grey)),
            Text(
              activityName, 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)
            ),
          ],
        ),
      ),
    );
  }
}