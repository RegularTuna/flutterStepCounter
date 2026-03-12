import 'package:flutter/material.dart';
import 'package:health/health.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  String _dailyStepCount = '0';
  String _weeklyStepCount = '0';
  bool _isLoading = false;
  final Health health = Health(); // Keep instance outside function

  Future<void> _fetchStepsOfTheDay() async {
  setState(() => _isLoading = true);

  try {
    // 1. Define o tipo de dado
    final types = [HealthDataType.STEPS];
    
    // 2. Configura e PEDE autorização (Obrigatório no Android 14+)
    await health.configure();
    bool requested = await health.requestAuthorization(types);

    if (requested) {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      int? steps = await health.getTotalStepsInInterval(midnight, now);

      setState(() {
        _dailyStepCount = (steps ?? 0).toString();
      });
    } else {
      setState(() => _dailyStepCount = "Permissão negada");
    }
  } catch (e) {
    setState(() => _dailyStepCount = "Erro: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<void> _fetchStepsOfTheWeek() async {
  setState(() => _isLoading = true);

  try {
    
    final types = [HealthDataType.STEPS];

    
    await health.configure();
    bool requested = await health.requestAuthorization(types);

    if (requested) {
      final now = DateTime.now();
      
      final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      
      int? steps = await health.getTotalStepsInInterval(sevenDaysAgo, now);

      setState(() {
        _weeklyStepCount = (steps ?? 0).toString();
      });
    } else {
      setState(() => _weeklyStepCount = "Permissão negada");
    }
  } catch (e) {
    setState(() => _weeklyStepCount = "Erro: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Adicionado para evitar erro de overflow se o ecrã for pequeno
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_walk, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 20),
          
          // --- SEÇÃO DIÁRIA ---
          const Text("Passos Hoje:", style: TextStyle(fontSize: 16)),
          Text(
            _dailyStepCount,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _fetchStepsOfTheDay,
            icon: const Icon(Icons.today),
            label: const Text("Atualizar Hoje"),
          ),

          const Divider(height: 60, indent: 50, endIndent: 50),

          // --- Weekly---
          const Text("Passos Últimos 7 Dias:", style: TextStyle(fontSize: 16)),
          Text(
            _weeklyStepCount,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _fetchStepsOfTheWeek,
            icon: const Icon(Icons.date_range),
            label: const Text("Atualizar Semana"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50),
          ),

          const SizedBox(height: 30),
          if (_isLoading) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}