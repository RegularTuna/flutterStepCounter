import 'package:flutter/material.dart';
import 'package:steps_health/utils/database_helper.dart';

class Dailysummary extends StatelessWidget {
  const Dailysummary({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: DbHelper.getDailyStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Walking", stats['WALKING'] ?? 0, Colors.green),
              _buildStatItem("Running", stats['RUNNING'] ?? 0, Colors.orange),
              _buildStatItem("Still", stats['STILL'] ?? 0, Colors.blueGrey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int seconds, Color color) {
    final double minutes = seconds / 60;

    return Column(
      children: [
        Text(
          "${minutes.toStringAsFixed(1)}m",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
