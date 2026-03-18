import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'health_tracker.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE activity_logs("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "type TEXT, "
          "start_time TEXT, "
          "end_time TEXT, "
          "duration_seconds INTEGER)",
          
        );
      },
      version: 2,
    );
    return _db!;
  }

  static Future<void> insertSession(
    String type,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final int duration = end.difference(start).inSeconds;

    // Ignora micro-sessões de menos de 2 segundos (ruído do sensor)
    if (duration < 2) return;

    await db.insert('activity_logs', {
      'type': type,
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'duration_seconds': duration,
    });
    print("Sessão gravada: $type por ${duration}s");
  }

  // Método para ler o histórico
  static Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'activity_logs',
      orderBy: 'start_time DESC',
      limit: limit,
    );
  }

  //Métod para retornar stats diarios
  static Future<Map<String, int>> getDailyStats() async {
    final db = await database;

    String today = DateTime.now().toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT type, SUM(duration_seconds) as total
      FROM activity_logs
      WHERE start_time LIKE ? 
      GROUP BY type
      ''',
      ['$today%'],
    );

    return {
      for (var item in results) item['type'] as String: item['total'] as int,
    };
  }
}
