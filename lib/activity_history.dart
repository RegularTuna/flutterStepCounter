import 'package:flutter/material.dart';
import 'package:steps_health/utils/database_helper.dart'; // Ajusta o path se necessário
import 'package:intl/intl.dart'; // Opcional: para formatar horas (flutter pub add intl)

class ActivityHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DbHelper.getHistory(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Sem histórico disponível."));
        }

        final logs = snapshot.data!;
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(log['type']),
              subtitle: Text("Duração: ${log['duration_seconds']}s"),
              trailing: Text(log['start_time'].toString().substring(11, 16)), // HH:mm
            );
          },
        );
      },
    );
  }

  Widget _getIcon(String type) {
    switch (type) {
      case 'WALKING': return Icon(Icons.directions_walk, color: Colors.green);
      case 'RUNNING': return Icon(Icons.directions_run, color: Colors.orange);
      case 'STILL': return Icon(Icons.accessibility_new, color: Colors.blueGrey);
      default: return Icon(Icons.help_outline);
    }
  }
}