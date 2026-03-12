import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
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
    _loadLogs(); // Carrega o histórico guardado ao iniciar

    // 1. Ouvir eventos de Geofence
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      print('[Geofence Event] identifier: ${event.identifier}, action: ${event.action}');
      
      // Criar mensagem legível
      String status = event.action == 'ENTER' ? "ENTROU" : "SAIU";
      _logEvent("$status em ${event.identifier}");
    });

    // 2. Configurar o Plugin
    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      locationUpdateInterval: 5000, 
      fastestLocationUpdateInterval: 1000,
      disableElasticity: true, 
      geofenceProximityRadius: 1000,
      enableHeadless: true,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: true, // Sons de debug ativos
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      reset: true,
      // Configuração de Notificação para Android (necessário para background estável)
      notification: bg.Notification(
        title: "Monitor de Presença Ativo",
        text: "A monitorizar entrada/saída de zonas.",
      ),
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }

      // 3. Adicionar a Geofence de Oiã
      bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: 'CASA_OIA',
        radius: 150,
        latitude: 40.5420,
        longitude: -8.53364,
        notifyOnEntry: true,
        notifyOnExit: true,
        loiteringDelay: 10000,
      )).then((bool success) {
        print('[addGeofence] Sucesso: $success');
      });
    });
  }

  // --- PERSISTÊNCIA DE DADOS ---

  Future<void> _logEvent(String text) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('geo_logs') ?? [];
    
    String timestamp = DateTime.now().toString().substring(11, 19);
    logs.insert(0, "$timestamp - $text");
    
    await prefs.setStringList('geo_logs', logs);
    
    // Atualiza a interface apenas se o widget ainda estiver no ecrã
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

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitor de Presença"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
            tooltip: "Limpar Histórico",
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade100,
            child: Column(
              children: [
                const Text(
                  "ZONA: Oiã (Raio: 200m)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Status: O motor está a correr em background",
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text("Sem eventos registados ainda."))
                : ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final isEntry = item.contains("ENTROU");
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEntry ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(
                            isEntry ? Icons.login : Icons.logout,
                            color: isEntry ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          item,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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