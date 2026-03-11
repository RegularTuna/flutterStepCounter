import 'dart:ffi';

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

  Future<void> _calculateDaiyDistanceTraveled() async{
    final prefs = await SharedPreferences.getInstance();

    List<String> _history = prefs.getStringList('gps_history') ?? [];
    
    double totalDist = 0;
    
    for(int i = _history.length -1; i > 0; i--){
        double? lat1 = _extractCoord(_history[i], 'Lat:');
        double? long1 = _extractCoord(_history[i], 'Long:');

        double? lat2 = _extractCoord(_history[i - 1], 'Lat:');
        double? long2 = _extractCoord(_history[i - 1], 'Long:');

        if (lat1 != null && long1 != null && lat2 != null && long2 != null) {
      
          totalDist += Geolocator.distanceBetween(lat1, long1, lat2, long2);
          
        }
    }

    

    setState(() {
      _locationLogs = List.from(_history);
      _totalDistance = totalDist.roundToDouble();
    });
  }
  

double? _extractCoord(String entry, String prefix) {
      final match = RegExp('$prefix (-?\\d+\\.\\d+)').firstMatch(entry);
      if (match != null) {
        return double.tryParse(match.group(1)!);
      }
      return null;
    }

  @override
  void initState() {
    _calculateDaiyDistanceTraveled();
    super.initState();
  }
  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _locationLogs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_locationLogs[index]),
                  
                );
              },),
          ),
          Text(_totalDistance.toString())
        ],
      ),
    )
      ;
  }
}