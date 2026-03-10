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
    await health.configure();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // This method asks the OS to do the math for you
    // It returns one single Integer instead of a list of points
    int? steps = await health.getTotalStepsInInterval(midnight, now);

    setState(() {
      _dailyStepCount = (steps ?? 0).toString();
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _dailyStepCount = "Erro: $e";
      _isLoading = false;
    });
  }
}

Future<void> _fetchStepsOfTheWeek() async {
  setState(() => _isLoading = true);

  try {
    await health.configure();
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    int? steps = await health.getTotalStepsInInterval(sevenDaysAgo, now);

    setState(() {
      _weeklyStepCount = (steps ?? 0).toString();
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _weeklyStepCount = "Erro: $e";
      _isLoading = false;
    });
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