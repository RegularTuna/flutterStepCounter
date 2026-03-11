import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  String _locationMessage = "Check your location";
  bool _isFetching = false;

  List<String> _history = [];

  // Read what the workmanager saved
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    print(_history.toString());
    setState(() {
      _history = prefs.getStringList('gps_history') ?? [];
      
    });
  }

  @override
  void initState() {
    
    
    super.initState();
    // Check permissions as soon as the screen opens
    _checkPermissionsAndInitBackground();
    
    
  }

  Future<void> _checkPermissionsAndInitBackground() async {
    // 1. Check basic permissions
    LocationPermission permission = await Geolocator.checkPermission();

    // 2. Ask the permission if it is the first time opening
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 3. If we have the permission "while in-use" ask for the "always" so it can be used in the background
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    // 4. workmanager starts only if we have "always" permission granted
    if (permission == LocationPermission.always) {
      _initBackgroundFetch();
      print("Workmanager: Successful registered");
    } else {
      setState(() {
        _locationMessage =
            "Need 'always' permission to run in the background";
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

      // Translate coordinates to actual address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        if (placemarks.isNotEmpty) {
          Placemark p = placemarks[0];
          _locationMessage = "${p.street}, ${p.locality}\n${p.country}";
        } else {
          _locationMessage =
              "lat: ${position.latitude}, Long: ${position.longitude}";
        }
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error: $e";
        _isFetching = false;
      });
    }
  }


  //Manual button
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                // If we don't yet have "always" allowed
                if (snapshot.hasData &&
                    snapshot.data != LocationPermission.always) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton.icon(
                      onPressed: () => Geolocator.openAppSettings(),
                      icon: const Icon(Icons.settings),
                      label: const Text("Configure 'Always allow'"),
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

            // Background history
            const Text(
              "Background history (15 min):",
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
              label: const Text("Update History"),
            ),
          ],
        ),
      ),
    );
  }
}
