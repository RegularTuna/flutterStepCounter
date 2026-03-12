import 'package:flutter/material.dart';
import 'package:steps_health/distance_traveled.dart';
import 'package:steps_health/geolocation_screen.dart';

import 'package:steps_health/gps_screen.dart';
import 'package:steps_health/step_counter_screen.dart';

import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

//To allow updates in background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      
      // address translation
      String address = "Unknown address";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = "${place.street}, ${place.locality}";
        }
        
      } catch (e) {
        address = "Error obtaining address";
      }


      // 1. Access the data storage
      final prefs = await SharedPreferences.getInstance();
      
      // 2. Read the current list (or create it )
      List<String> history = prefs.getStringList('gps_history') ?? [];
      
      // 3. Create a new line with date and coordinates
      String time = DateTime.now().toString().substring(0, 19); // HH:mm:ss
      
      String entry = "$time -> Address: $address -> Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)} \n";
      
      // 4. Add it to the top of the list and keep only the last 10 entries
      history.insert(0, entry);
      if (history.length > 20) history.removeLast();
      
      // 5. Saev it
      await prefs.setStringList('gps_history', history);
      
      
      return Future.value(true);
    } catch (err) {
      return Future.value(false);
    }
    
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initiate workmanager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            children: [
              //Expanded(child: DistanceTravell()),
              //Expanded(child: GpsScreen()),
              //Expanded(child: StepCounterWidget()),
              Expanded(child: GeolocationScreen())
            ],
          )
        ),
      ),
      
    );
  }
}
