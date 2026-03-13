import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';


class WifiConnectionScreen extends StatefulWidget {
  const WifiConnectionScreen({super.key});

  @override
  State<WifiConnectionScreen> createState() => _WifiConnectionScreenState();
}

class _WifiConnectionScreenState extends State<WifiConnectionScreen> {

  final info = NetworkInfo();

  String? _wifiName; // "FooNetwork"
  String? _wifiBSSID; // 11:22:33:44:55:66
  String? _wifiGateway; // 192.168.1.1


  @override
  void initState() {
    _getWifiData();
    super.initState();
  }

  Future<void> _getWifiData() async{

    String? name = await info.getWifiName();
    String? BSSID = await info.getWifiBSSID();
    String? gateway = await info.getWifiGatewayIP();

    setState(() {
      _wifiName = name;
      _wifiBSSID = BSSID;
      _wifiGateway = gateway;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wi-fi details"),
      ),
      body: Center(
        child: Column(
          children: [
            Text(_wifiName ?? "Unknown"),
            Text(_wifiBSSID ?? "Unknown"),
            Text(_wifiGateway ?? "Unknown")
          ],
      ) ,
      )
      
    );
  }
}