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
  double _totalPhoneMinutes = 0.0;

  int _unlockCount = 0;
  int _interactionCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshAllStats();
  }

  Future<void> _refreshAllStats() async {
    await _getUsage();
    await _getUnlocks();
  }

  Future<void> _getUsage() async {
    bool? isPermission = await usage.UsageStats.checkUsagePermission();
    if (isPermission == null || !isPermission) {
      await usage.UsageStats.grantUsagePermission();
      return;
    }

    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;

    List<usage.UsageInfo> stats = await usage.UsageStats.queryUsageStats(startDate, endDate);

    List<String> communicationApps = [
      'com.whatsapp', 'com.facebook.orca', 'org.telegram.messenger',
      'com.instagram.android', 'com.discord', 'com.google.android.apps.messaging',
      'com.android.mms', 'com.google.android.dialer', 'com.android.server.telecom',
      'com.samsung.android.messaging',
    ];

    Map<String, int> groupedUsage = {};

    for (var info in stats) {
      String pkg = info.packageName ?? "unknown";
      int timeMs = int.parse(info.totalTimeInForeground ?? '0');
      
      if (timeMs > 0) {
        // EM VEZ DE SOMAR (+), verificamos qual é o maior valor registado
        // O Android UsageStats já guarda o acumulado no totalTimeInForeground
        if (!groupedUsage.containsKey(pkg) || timeMs > groupedUsage[pkg]!) {
          groupedUsage[pkg] = timeMs;
        }
      }
    }

    // 2. AGORA CALCULAMOS OS TOTAIS COM OS VALORES ÚNICOS
    double totalSumMs = 0;
    double commSumMs = 0;
    List<usage.UsageInfo> commList = [];

    groupedUsage.forEach((pkg, timeMs) {
      totalSumMs += timeMs; // Soma o valor máximo de cada app ao total do telemóvel

      if (communicationApps.contains(pkg)) {
        commSumMs += timeMs;
        commList.add(usage.UsageInfo(
          packageName: pkg,
          totalTimeInForeground: timeMs.toString(),
        ));
      }
    });

    // 3. ORDENAR POR TEMPO (MAIS USADA PRIMEIRO)
    commList.sort((a, b) => 
      int.parse(b.totalTimeInForeground!).compareTo(int.parse(a.totalTimeInForeground!)));

    setState(() {
      _usageStats = commList;
      _totalCommunicationMinutes = commSumMs / 1000 / 60;
      _totalPhoneMinutes = totalSumMs / 1000 / 60;
    });
  }


  Future<void> _getUnlocks() async{

    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;


   try {
    List<usage.EventUsageInfo> events = await usage.UsageStats.queryEvents(startDate, endDate);

    if (events.isEmpty) {
      print("Aviso: O sistema ainda não devolveu eventos hoje.");
      return; // Não atualiza para 0 se a lista vier vazia por erro
    }

    
    // Usamos um Set para guardar timestamps e evitar contar o mesmo desbloqueio 
    // que gera múltiplos eventos no mesmo segundo
    Set<int> uniqueUnlocks = {};
    Set<int> uniqueInteractions = {};


    for (var event in events) {
      // 18 = Ecra desbloqueado
      if (event.eventType == "18") {
        int timestamp = int.parse(event.timeStamp!) ~/ 1000; 
        uniqueUnlocks.add(timestamp);

      // 15 = Ecra ligou
      }else if(event.eventType == "15"){
        int timestamp = int.parse(event.timeStamp!) ~/ 1000; 
        uniqueInteractions.add(timestamp);
      }
    }

    
    setState(() {
      // Se o Set for muito grande (devido ao evento 7), 
      // podemos contar apenas eventos com diferença de pelo menos 2 segundos
      _unlockCount = uniqueUnlocks.length;
      _interactionCount = uniqueInteractions.length;
    });
  } catch (e) {
    print("Erro ao ler desbloqueios: $e");
  }
  }


String _formatTime(double totalMinutes) {
  if (totalMinutes < 1) {
    int seconds = (totalMinutes * 60).toInt();
    return "${seconds}s";
  }
  
  int hours = totalMinutes ~/ 60; // Divisão inteira para as horas
  int minutes = (totalMinutes % 60).toInt(); // O resto são os minutos

  if (hours > 0) {
    return "${hours}h ${minutes}min";
  } else {
    return "${minutes}min";
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CARD DE RESUMO DUPLO
        Card(
          margin: const EdgeInsets.all(10),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildSummaryRow("Uso Total Hoje", _totalPhoneMinutes, Icons.phone_android, Colors.blueGrey),
                const Divider(),
                _buildSummaryRow("Comunicação", _totalCommunicationMinutes, Icons.forum, Colors.blue),
              ],
            ),
          ),
        ),
        
        ListTile(
          title: const Text("Detalhes por App (Comunicação)", style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _getUsage),
        ),

        Expanded(
          child: _usageStats.isEmpty
              ? const Center(child: Text("Sem dados de comunicação hoje"))
              : ListView.builder(
                  itemCount: _usageStats.length,
                  itemBuilder: (context, index) {
                    final info = _usageStats[index];
                    double minutes = int.parse(info.totalTimeInForeground!) / 1000 / 60;

                    return ListTile(
                      leading: const Icon(Icons.android, color: Colors.green),
                      title: Text(info.packageName!.split('.').last.toUpperCase()),
                      subtitle: Text(info.packageName!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(_formatTime(minutes), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        Card(
          color: Colors.blue[50],
          elevation: 5,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text("Unlocks", style: TextStyle(fontSize: 16)),
                    Text("$_unlockCount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange))
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text("Interactions", style: TextStyle(fontSize: 16)),
                    Text("$_interactionCount",style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange))
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  // Widget auxiliar para as linhas de resumo
  Widget _buildSummaryRow(String label, double value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          _formatTime(value),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}