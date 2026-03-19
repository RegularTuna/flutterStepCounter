import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TypingSpeed extends StatefulWidget {
  const TypingSpeed({super.key});

  @override
  State<TypingSpeed> createState() => _TypingSpeedState();
}

class _TypingSpeedState extends State<TypingSpeed> {
  final TextEditingController _controller = TextEditingController();

  DateTime? _startTime;
  DateTime? _lastTapTime;
  int _charCount = 0;
  double _cpm = 0.0;
  double _avgLastWeek = 0;
  List<double> _entriesLastWeek = [];


  @override
  void initState() {
    _loadSavedData();
    super.initState();
  }


  Future<void> _loadSavedData() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedList = prefs.getStringList('typing_entries');

    if (_entriesLastWeek.isNotEmpty) {
      double total = 0;
      for (var e in _entriesLastWeek) {
        total += e;
      }
      _avgLastWeek = total / _entriesLastWeek.length;
    }
  }

  void _reset() {
    setState(() {
      _startTime = null;
      _lastTapTime = null;
      _charCount = 0;
      _cpm = 0.0;
    });
  }

  void _handleTyping(String text) {
    if (text.isEmpty) {
      _reset();
      return;
    }


    // Inicia o cronómetro apenas no primeiro toque
    _startTime ??= DateTime.now();

    _lastTapTime = DateTime.now();
    _charCount = text.length;

    _calculateMetrics();
  }

  void _calculateMetrics() {
    if (_startTime == null || _lastTapTime == null || _charCount < 2) return;

    // Diferença exata entre o primeiro e o último caracter digitado
    final durationMs = _lastTapTime!.difference(_startTime!).inMilliseconds;

    if (durationMs > 500) {
      // Evita cálculos com menos de meio segundo
      double seconds = durationMs / 1000;
      
      setState(() {
        // Extrapolação para 60 segundos (CPM)
        _cpm = (_charCount / seconds) * 60;
       
      });
    }
  }

void _saveFinalScore(){
  if (_cpm > 0 ){
    _calculateAverage(_cpm);
    _controller.clear();
    _reset();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Result saved on average metric"))
    );
  }
}

  Future<void> _calculateAverage(double newEntry) async{
    final now = DateTime.now();
    _entriesLastWeek.add(newEntry);
    String entryWithDate = "${now.toIso8601String()}|$newEntry";

    double totalTimeSum = 0;
    for (var entry in _entriesLastWeek) {
      totalTimeSum+=entry;
    }

    setState(() {
      _avgLastWeek = (totalTimeSum/_entriesLastWeek.length);
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();


    List<String> savedEntries = prefs.getStringList('typing_entries') ?? [];

    savedEntries.add(entryWithDate);

    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    savedEntries = savedEntries.where((item) {
      DateTime itemDate = DateTime.parse(item.split('|')[0]);
      return itemDate.isAfter(sevenDaysAgo);
    }).toList();

    await prefs.setStringList('typing_entries', savedEntries);

    _loadSavedData();

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Typing speed", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
        const SizedBox(height: 10),
        Text("Write about something"),
        TextField(
          controller: _controller,
          onChanged: _handleTyping,
          maxLines: null,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Type here...",
            ),
        ),
        const SizedBox(height: 20,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metricTile("Chars", "$_charCount"),
            _metricTile("Speed (cpm)", _cpm.toStringAsFixed(0))
          ],
        ),
        const SizedBox(height: 20,),
        ElevatedButton.icon(
          onPressed: _saveFinalScore,
          icon: const Icon(Icons.refresh),
          label: const Text("Finish"),
        ),
        Card(
          elevation: 2,
          color: Colors.blue[100],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _metricTile("Average CPM Last Week", _avgLastWeek.round().toString()),
          ),
        )
      ],
    
    );
  }
}


Widget _metricTile(String label, String value){

  return Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),)
    ],
  );
}