import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:shared_preferences/shared_preferences.dart';

class GeolocationScreen extends StatefulWidget {
  const GeolocationScreen({super.key});

  @override
  State<GeolocationScreen> createState() => _GeolocationScreenState();
}

class _GeolocationScreenState extends State<GeolocationScreen> {
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadLogs(); // loads history on app start

    // 1. Listen to GeoFence events
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      String status = event.action == 'ENTER' ? "ENTROU" : "SAIU";
      String message = "$status em ${event.identifier}";

      // 1. update the local storage so the UI updates immediatly
      String timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _history.insert(0, "$timestamp - $message");
      });

      // 2. Saves locally
      _logEvent(message);
    });

    // 2. Plugin config
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0,
        locationUpdateInterval: 5000,
        fastestLocationUpdateInterval: 1000,
        disableElasticity: true,
        geofenceProximityRadius: 1000,
        enableHeadless: true,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: false, // To hear sounds when something happens (just for debug)
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        reset: true,
        // Necessary to keep background stable in android
        notification: bg.Notification(
          title: "Monitoring presence",
          text: "Monitoring entries and exits",
        ),
      ),
    ).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }

      // 3. Testing for current location

      /*bg.BackgroundGeolocation.addGeofence(
        bg.Geofence(
          identifier: 'Oia',
          radius: 150,
          latitude: 40.5420,
          longitude: -8.53364,
          notifyOnEntry: true,
          notifyOnExit: true,
          loiteringDelay: 10000,
        ),
      ).then((bool success) {
        print('[addGeofence] Sucesso: $success');
      });*/
    });
  }

  // --- Data persistance ---

  Future<void> _logEvent(String text) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('geo_logs') ?? [];

    String timestamp = DateTime.now().toString().substring(11, 19);
    logs.insert(0, "$timestamp - $text");

    await prefs.setStringList('geo_logs', logs);

    // Updates UI if the widget is still on screen
    if (mounted) {
      setState(() {
        _history = logs;
      });
    }
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('geo_logs') ?? [];
    });
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('geo_logs');
    setState(() {
      _history = [];
    });
  }

  void _showHistorySheet(BuildContext context) async {
    // Waits for the updated logs
    await _loadLogs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // starts at 60% of the screen
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Event History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(child: Text("No logs found."))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return ListTile(
                              leading: Icon(
                                item.contains("ENTROU")
                                    ? Icons.login
                                    : Icons.logout,
                                color: item.contains("ENTROU")
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(item),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //set location manually

  final TextEditingController _lat = TextEditingController();
  final TextEditingController _long = TextEditingController();

  String _storedLat = "";
  String _storedLong = "";

  void _updateGeofenceManually() {
    // 1. Converter o texto dos controllers para Double
    double? lat = double.tryParse(_lat.text);
    double? long = double.tryParse(_long.text);

    if (lat == null || long == null) {
      print("Erro: Coordenadas inválidas");
      return;
    }

    // 2. Remover a geofence antiga (opcional, para não acumular)
    bg.BackgroundGeolocation.removeGeofence("CASA_OIA").then((success) {
      // 3. Adicionar a nova geofence com as coordenadas do utilizador
      bg.BackgroundGeolocation.addGeofence(
        bg.Geofence(
          identifier: 'CASA_OIA',
          radius: 200, // Recomendo 200 para evitar o erro que vimos antes
          latitude: lat,
          longitude: long,
          notifyOnEntry: true,
          notifyOnExit: true,
        ),
      ).then((bool success) {
        print('[addGeofence] Nova localização manual definida: $success');
        _logEvent("Nova Geofence em: $lat, $long");
      });
    });
  }

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presence Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistorySheet(context),
            tooltip: "Show full history",
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
            tooltip: "Clear history",
          ),
        ],
      ),
      body: Column(
        children: [
          Column(
            children: [
              TextField(
                controller: _lat,
                decoration: InputDecoration(labelText: 'Latitude (ex: 40.54)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _long,
                decoration: InputDecoration(labelText: 'Longitude (ex: -8.53)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              ElevatedButton(
                onPressed: _updateGeofenceManually,
                child: Text("Define new Geofence"),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade100,
            child: Column(
              children: [
                const Text(
                  "Geofencing Area",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Running on background",
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text("No events yet"))
                : ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final isEntry = item.contains("ENTROU");

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEntry
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            isEntry ? Icons.login : Icons.logout,
                            color: isEntry ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
