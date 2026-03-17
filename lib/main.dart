import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:steps_health/distance_traveled.dart';
//import 'package:steps_health/geolocation_screen.dar';

import 'package:steps_health/gps_screen.dart';
import 'package:steps_health/motion_detection.dart';
import 'package:steps_health/step_counter_screen.dart';
import 'package:steps_health/wifi_connection.dart';

import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
//import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
//    as bg;

import 'package:network_info_plus/network_info_plus.dart';

//To allow updates in background for the gps location
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = NetworkInfo();
      final now = DateTime.now();

      // --- 1. LÓGICA WI-FI (PRESENCE & HISTORY) ---
      try {
        String todayKey =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        String? savedHomeBSSID = prefs.getString('home_bssid');
        String? currentBSSID = await info.getWifiBSSID();

        if (currentBSSID != null && currentBSSID == savedHomeBSSID) {
          // Carregar mapa de histórico
          String historyRaw = prefs.getString('home_time_history_map') ?? "{}";
          Map<String, dynamic> historyMap = jsonDecode(historyRaw);

          // Incrementar tempo
          int currentMinutes = historyMap[todayKey] ?? 0;
          historyMap[todayKey] = currentMinutes + 15;

          // Manter apenas últimos 7 dias
          var dateKeys = historyMap.keys.toList()..sort();
          if (dateKeys.length > 7) {
            historyMap.remove(dateKeys.first);
          }

          // Guardar dados
          await prefs.setString(
            'home_time_history_map',
            jsonEncode(historyMap),
          );
          await prefs.setInt('minutes_at_home_today', historyMap[todayKey]);
        }
      } catch (e) {
        print("WiFi background error: $e");
      }

      // --- 2. LÓGICA GPS (O teu código original) ---
      Position position = await Geolocator.getCurrentPosition();
      String address = "Unknown address";

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = "${place.street}, ${place.locality}";
        }
      } catch (e) {
        address = "Error obtaining address";
      }

      List<String> history = prefs.getStringList('gps_history') ?? [];
      String time = now.toString().substring(0, 19);
      String entry =
          "$time -> Address: $address -> Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)} \n";

      history.insert(0, entry);
      if (history.length > 20) history.removeLast();

      await prefs.setStringList('gps_history', history);

      return Future.value(true);
    } catch (err) {
      print("Global background error: $err");
      return Future.value(false);
    }
  });
}

//geolation in the background
/*
 @pragma('vm:entry-point')
 void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
   switch (headlessEvent.name) {
     case bg.Event.GEOFENCE:
       bg.GeofenceEvent event = headlessEvent.event;
       print('- Headless Geofence Event: ${event.identifier}, ${event.action}');
      
       // Como a app está fechada, não há setState. 
       // Temos de gravar diretamente no SharedPreferences.
       final prefs = await SharedPreferences.getInstance();
       List<String> logs = prefs.getStringList('geo_logs') ?? [];
      
      String timestamp = DateTime.now().toString().substring(11, 19);
      String status = event.action == 'ENTER' ? "ENTROU" : "SAIU";
      
      logs.insert(0, "$timestamp - [OFFLINE] $status em ${event.identifier}");
      await prefs.setStringList('geo_logs', logs);
      break;
  }
}
*/

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initiate workmanager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Workmanager().registerPeriodicTask(
    "1", // ID
    "periodicLocationUpdate", // Name
    frequency: const Duration(minutes: 15), // 15 min is the minimum
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.notRequired, // runs without interner
      requiresBatteryNotLow:
          true, // Better to save battery but we will lose data that should be recorded (to check)
    ),
  );

  FlutterForegroundTask.initCommunicationPort();
  runApp(const MyApp());

  //Mantains geolocation active even with app closed
  //bg.BackgroundGeolocation.registerHeadlessTask(backgroundGeolocationHeadlessTask); **------ uncomment for geocoding
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: PageView(
          scrollDirection: Axis.vertical, // Scroll de cima para baixo
          children: [
            // Cada um destes ocupará o ecrã inteiro automaticamente
            Padding(padding: EdgeInsets.all(8.0), child: GpsScreen()),
            Padding(padding: EdgeInsets.all(8.0), child: WifiConnectionScreen()),
            Padding(padding: EdgeInsets.all(8.0), child: DistanceTravell()),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: StepCounterWidget(),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: MotionDetection(),
            ),
          ],
        ),
      ),
    );
  }
}
