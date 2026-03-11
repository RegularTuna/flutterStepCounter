import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  String _locationMessage = "Check your location";
  bool _isFetching = false;

  List<String> _history = [];

  // Função para ler o que o Workmanager guardou
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('gps_history') ?? [];
    });
  }

  @override
  void initState() {
    super.initState();
    // Chamamos a função de verificação assim que o ecrã abre
    _checkPermissionsAndInitBackground();
  }

  Future<void> _checkPermissionsAndInitBackground() async {
    // 1. Verificamos se as permissões básicas já existem
    LocationPermission permission = await Geolocator.checkPermission();

    // 2. Se for a primeira vez, pedimos a permissão normal
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 3. Se tivermos a permissão "Durante o Uso", pedimos o upgrade para "Sempre"
    // No Android 10+, o Workmanager PRECISA do "Sempre" para ler o GPS em background
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    // 4. SÓ registamos a tarefa se o utilizador deu a permissão "Always"
    if (permission == LocationPermission.always) {
      _initBackgroundFetch();
      print("Workmanager: Registado com sucesso.");
    } else {
      setState(() {
        _locationMessage =
            "O rastreio em background requer a permissão 'Permitir Sempre'.";
      });
    }
  }

  void _initBackgroundFetch() {
    Workmanager().registerPeriodicTask(
      "1", // ID
      "periodicLocationUpdate", // Name
      frequency: const Duration(minutes: 15), // 15 min is the minimum
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.notRequired, // runs without interner
        requiresBatteryNotLow:
            true, // Better to save battery but we will lose data (to check)
      ),
    );
  }

  Future<void> _updatePosition() async {
    setState(() {
      _isFetching = true;
    });

    try {
      Position position = await _determinePosition();

      setState(() {
        _locationMessage =
            "lat: ${position.latitude}, Long: ${position.longitude}";
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error: $e";
        _isFetching = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission = await Geolocator.checkPermission();

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() => _locationMessage = "Permissão básica negada.");
      
    }
  }

  // PASSO 2: Forçar o pedido de Background (Always)
  // Se já temos "whileInUse", chamamos o requestPermission NOVAMENTE.
  // No Android 11+, isto NÃO abre um pop-up, abre as DEFINIÇÕES DO SISTEMA.
  if (permission == LocationPermission.whileInUse) {
    print("A pedir upgrade para 'Always'...");
    
    // IMPORTANTE: No Android, tens de chamar isto para ele abrir as definições
    permission = await Geolocator.requestPermission();
    
    // Se o utilizador voltar da janela de definições sem mudar para "Sempre"
    if (permission != LocationPermission.always) {
      setState(() => _locationMessage = "Vá às definições e escolha 'Permitir Sempre'.");
      
    }
  }

  // PASSO 3: Se chegámos aqui com "Always", ligamos o motor
  if (permission == LocationPermission.always) {
    _initBackgroundFetch();
    _loadHistory();
    setState(() => _locationMessage = "Rastreio de Background Ativo!");
  }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissões negadas permanentemente.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, // Ou .low para poupar bateria
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Importante para a lista não cortar o ecrã
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(_locationMessage, textAlign: TextAlign.center),



            FutureBuilder<LocationPermission>(
            future: Geolocator.checkPermission(),
            builder: (context, snapshot) {
              // Se ainda não temos a permissão "Always", mostramos o botão de ajuda
              if (snapshot.hasData && snapshot.data != LocationPermission.always) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text("Configurar 'Permitir Sempre'"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _updatePosition,
              child: const Text("Obter GPS Agora"),
            ),

            const Divider(height: 50, indent: 40, endIndent: 40),

            // SEÇÃO DE HISTÓRICO
            const Text(
              "Histórico de Background (15 min):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ..._history
                .map(
                  (log) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
                .toList(),

            const SizedBox(height: 15),

            TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text("Atualizar Histórico"),
            ),
          ],
        ),
      ),
    );
  }
}
