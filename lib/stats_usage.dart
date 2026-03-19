import 'package:flutter/material.dart';

import 'package:usage_stats_new/usage_stats.dart' as usage;

class UsageStatsState extends StatefulWidget {
  const UsageStatsState({super.key});

  @override
  State<UsageStatsState> createState() => _UsageStatsStateState();
}

class _UsageStatsStateState extends State<UsageStatsState> {
  List<usage.UsageInfo> _usageStats = [];
  double _totalCommunicationMinutes = 0.0;

  @override
  void initState() {
    super.initState();
    _getUsage();
  }

  Future<void> _getUsage() async {
    bool? isPermission = await usage.UsageStats.checkUsagePermission();
    if (isPermission == null || !isPermission) {
      await usage.UsageStats.grantUsagePermission();
      return;
    }

    DateTime now = DateTime.now();

    // Define o início como sendo hoje às 00:00:00
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;

    List<usage.UsageInfo> stats = await usage.UsageStats.queryUsageStats(
      startDate,
      endDate,
    );

    List<String> communicationApps = [
      'com.whatsapp',
      'com.facebook.orca',
      'org.telegram.messenger',
      'com.instagram.android',
      'com.google.android.apps.messaging',
      'com.android.server.telecom',
      'com.discord',
      'com.google.android.apps.messaging', // SMS Padrão Google
      'com.android.mms',                   // SMS Padrão Antigo
      'com.google.android.dialer',          // App de Telefone (Google/Pixel)
      'com.android.server.telecom',         // Gestor de chamadas do sistema
      'com.samsung.android.messaging',      // Se o paciente usar Samsung
    ];

    // 2. Filtrmos a lista de stats
    List<usage.UsageInfo> onlyCommunicationStats = stats.where((info) {
      // Regra 1: Tem de ser uma app da nossa lista de comunicação
      bool isComm = communicationApps.contains(info.packageName);

      // Tem de ter mais de 0 minutos de uso
      bool hasTime = int.parse(info.totalTimeInForeground ?? '0') > 0;

      return isComm && hasTime;
    }).toList();

    //Ordenamos (da mais usada para a menos usada)
    onlyCommunicationStats.sort(
      (a, b) => int.parse(
        b.totalTimeInForeground!,
      ).compareTo(int.parse(a.totalTimeInForeground!)),
    );

    double somaFinal = onlyCommunicationStats.fold(0, (prev, element) {
      return prev +
          (int.parse(element.totalTimeInForeground ?? '0') / 1000 / 60);
    });
    setState(() {
      _usageStats =
          onlyCommunicationStats; // Agora a lista só tem apps de comunicação
      _totalCommunicationMinutes = somaFinal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(10),
          color: Colors.blue.shade50,
          child: ListTile(
            leading: const Icon(Icons.forum, color: Colors.blue),
            title: const Text("Tempo de Comunicação (Hoje)"),
            subtitle: Text(
              "Total: ${_totalCommunicationMinutes.toStringAsFixed(1)} minutos",
            ),
          ),
        ),
        ListTile(
          title: const Text(
            "Detalhes por App",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getUsage,
          ),
        ),
        Expanded(
          child: _usageStats.isEmpty
              ? const Center(child: Text("Sem dados ou permissão negada"))
              : ListView.builder(
                  itemCount: _usageStats.length > 15 ? 15 : _usageStats.length,
                  itemBuilder: (context, index) {
                    final info = _usageStats[index];
                    double minutes =
                        int.parse(info.totalTimeInForeground!) / 1000 / 60;

                    return ListTile(
                      leading: const Icon(Icons.android, color: Colors.green),
                      title: Text(info.packageName!.split('.').last),
                      subtitle: Text(
                        info.packageName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text("${minutes.toStringAsFixed(1)}min"),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
