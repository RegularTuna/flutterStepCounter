import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WifiConnectionScreen extends StatefulWidget {
  const WifiConnectionScreen({super.key});

  @override
  State<WifiConnectionScreen> createState() => _WifiConnectionScreenState();
}

class _WifiConnectionScreenState extends State<WifiConnectionScreen> {
  final info = NetworkInfo();

  String? _wifiName;
  String? _wifiBSSID;
  String? _wifiGateway;
  String? _savedHomeBSSID;

  @override
  void initState() {
    _getWifiData();
    super.initState();
  }

  Future<void> _loadData() async {
    await _getWifiData();
    await _loadSavedHomeWifi();
  }

  Future<void> _loadSavedHomeWifi() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedHomeBSSID = prefs.getString('home_bssid');
    });
  }

  Future<void> _getWifiData() async {
    try {
      String? name = await info.getWifiName();
      String? BSSID = await info.getWifiBSSID();
      String? gateway = await info.getWifiGatewayIP();

      setState(() {
        _wifiName = name;
        _wifiBSSID = BSSID;
        _wifiGateway = gateway;
      });
    } catch (e) {
      print("error obtaining wi-fi data: $e");
    }
  }

  Future<void> _setAsHomeWifi() async {
    if (_wifiBSSID == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_bssid', _wifiBSSID!);
    await prefs.setString('home_name', _wifiName ?? "Unknown");

    setState(() {
      _savedHomeBSSID = _wifiBSSID;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Home wi-fi saved")));
  }

  Future<List<MapEntry<String, int>>> _getWeeklyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String historyRaw = prefs.getString('home_time_history_map') ?? "{}";
    Map<String, dynamic> historyMap = jsonDecode(historyRaw);

    // Convertemos para uma lista de entradas e ordenamos por data (decrescente)
    List<MapEntry<String, int>> sortedHistory = historyMap.entries
        .map((e) => MapEntry(e.key, e.value as int))
        .toList();

    sortedHistory.sort((a, b) => b.key.compareTo(a.key));
    return sortedHistory;
  }

  @override
  Widget build(BuildContext context) {
    bool isAtHome = _wifiBSSID != null && _wifiBSSID == _savedHomeBSSID;

    return Scaffold(
      appBar: AppBar(title: const Text("Wi-Fi Presence")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: isAtHome ? Colors.green.shade50 : Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isAtHome ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  isAtHome ? Icons.home : Icons.location_off,
                  color: isAtHome ? Colors.green : Colors.orange,
                ),
                title: Text(
                  isAtHome ? "You are at Home" : "You are Away",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAtHome ? Colors.green.shade900 : Colors.orange.shade900,
                  ),
                ),
                subtitle: Text("Current network: ${_wifiName ?? 'Unknown'}"),
              ),
            ),
            const SizedBox(height: 20),
            Text("BSSID: ${_wifiBSSID ?? "N/A"}", style: const TextStyle(color: Colors.grey)),
            Text("Gateway: ${_wifiGateway ?? "N/A"}", style: const TextStyle(color: Colors.grey)),
            
            const Divider(height: 40),
            const Text(
              "Last 7 Days Presence",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder<List<MapEntry<String, int>>>(
                future: _getWeeklyHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No history recorded yet."));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final entry = snapshot.data![index];
                      final totalMinutes = entry.value;

                      // Calculate Hours and Minutes
                      int hours = totalMinutes ~/ 60;
                      int minutes = totalMinutes % 60;

                      String timeLabel = hours > 0 
                          ? "${hours}h ${minutes}m" 
                          : "${minutes}m";

                      return ListTile(
                        leading: const Icon(Icons.history, size: 20),
                        title: Text(_formatDateLabel(entry.key)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            timeLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            if (_wifiBSSID != null && _wifiBSSID != _savedHomeBSSID)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _setAsHomeWifi,
                  icon: const Icon(Icons.save),
                  label: const Text("Set as Home Wi-Fi"),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _getWifiData,
                child: const Text("Refresh Connection"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to make dates look better
  String _formatDateLabel(String dateKey) {
    final now = DateTime.now();
    String today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    if (dateKey == today) return "Today";
    
    // Optional: Return "Yesterday" logic could go here
    return dateKey;
  }
}