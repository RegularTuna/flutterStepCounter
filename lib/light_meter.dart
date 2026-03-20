import 'dart:async';

import 'package:flutter/material.dart';
import 'package:light/light.dart';

class LightMeter extends StatefulWidget {
  const LightMeter({super.key});

  @override
  State<LightMeter> createState() => _LightMeterState();
}

class _LightMeterState extends State<LightMeter> {

  StreamSubscription<int>? _lightEvents;
  int _currentLux = 0;

  void startListening() async {
  try {
    // 1. Pedir autorização
    await Light().requestAuthorization();
    
    // 2. Pegar apenas o PRIMEIRO valor e fechar automaticamente
    int luxValue = await Light().lightSensorStream.first;
    
    if (mounted) {
      setState(() {
        _currentLux = luxValue;
      });
    }
  } catch (e) {
    print("Erro ao medir lux: $e");
  }
}


@override
void dispose() {
  stopListening();
  super.dispose();
}

void stopListening() {
  _lightEvents?.cancel();
  _lightEvents = null; // Boa prática para evitar chamadas duplicadas
}

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: Card(
              elevation: 5,
              color: Colors.amber[300],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_currentLux.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              ),
            ),
          ),
          SizedBox(height:20),
          SizedBox(
            width: 130,
            height: 70,
            child: ElevatedButton(onPressed: startListening, child: const Text("Measure lux")))
        ],
      ),
    );
  }
}