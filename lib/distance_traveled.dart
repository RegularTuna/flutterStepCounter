import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DistanceTravell extends StatefulWidget {
  const DistanceTravell({super.key});

  @override
  State<DistanceTravell> createState() => _DistanceTravellState();
}

class _DistanceTravellState extends State<DistanceTravell> {
  List<String> _locationLogs = [];
  double _totalDistance = 0.0;


  
  @override
    void initState() {
      _calculateDaiyDistanceTraveled();
      super.initState();
    }


  Future<void> _calculateDaiyDistanceTraveled() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList('gps_history') ?? [];

    String today = DateTime.now().toString().substring(0,10);
    
    double totalDist = _calculateDistanceInADay(history, today);

    setState(() {
      _locationLogs = history.where((e) => e.startsWith(today)).toList();
      _totalDistance = totalDist;
    });
  }

    

  double? _extractCoord(String entry, String prefix) {
    final match = RegExp('$prefix (-?\\d+\\.\\d+)').firstMatch(entry);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  double _calculateDistanceInADay(List<String> data, String day){

    List<String> dailyData = data.where((entry) => entry.startsWith(day)).toList();

    double totalDist = 0;

    for (int i = dailyData.length - 1; i > 0; i--) {
      double? lat1 = _extractCoord(dailyData[i], 'Lat:');
      double? long1 = _extractCoord(dailyData[i], 'Long:');

      double? lat2 = _extractCoord(dailyData[i - 1], 'Lat:');
      double? long2 = _extractCoord(dailyData[i - 1], 'Long:');

      if (lat1 != null && long1 != null && lat2 != null && long2 != null) {
        totalDist += Geolocator.distanceBetween(lat1, long1, lat2, long2);
      }
    }
    return totalDist;
  }

  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _locationLogs.isEmpty 
              ? const Center(child: Text("Ainda não há movimentos hoje"))
              : ListView.builder(
                  itemCount: _locationLogs.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.deepPurple),
                        title: Text(_locationLogs[index], style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.05),
              border: const Border(top: BorderSide(color: Colors.deepPurple, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total hoje:", style: TextStyle(fontSize: 16)),
                Text(
                  "${_totalDistance.toStringAsFixed(1)} metros",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
