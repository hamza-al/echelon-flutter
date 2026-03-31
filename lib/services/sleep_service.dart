import 'package:hive_ce/hive.dart';

class SleepEntry {
  final String id;
  final DateTime date;
  final double hours;
  final String quality;
  final int qualityIndex;
  final int bedtimeHour;
  final int bedtimeMinute;
  final int wakeHour;
  final int wakeMinute;

  SleepEntry({
    required this.id,
    required this.date,
    required this.hours,
    required this.quality,
    required this.qualityIndex,
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.wakeHour,
    required this.wakeMinute,
  });

  String get bedtimeFormatted => _fmt(bedtimeHour, bedtimeMinute);
  String get wakeFormatted => _fmt(wakeHour, wakeMinute);

  static String _fmt(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final hr = h % 12 == 0 ? 12 : h % 12;
    return '$hr:${m.toString().padLeft(2, '0')} $period';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'hours': hours,
        'quality': quality,
        'qualityIndex': qualityIndex,
        'bedtimeHour': bedtimeHour,
        'bedtimeMinute': bedtimeMinute,
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
      };

  static double _calcHours(int bH, int bM, int wH, int wM) {
    final bed = bH * 60 + bM;
    final wake = wH * 60 + wM;
    var diff = wake - bed;
    if (diff <= 0) diff += 24 * 60;
    return diff / 60.0;
  }

  static SleepEntry? tryFromMap(dynamic raw) {
    if (raw is! Map) return null;
    try {
      final bH = (raw['bedtimeHour'] as num?)?.toInt() ?? 23;
      final bM = (raw['bedtimeMinute'] as num?)?.toInt() ?? 0;
      final wH = (raw['wakeHour'] as num?)?.toInt() ?? 7;
      final wM = (raw['wakeMinute'] as num?)?.toInt() ?? 0;
      var hours = (raw['hours'] as num?)?.toDouble() ?? 0;
      if (hours <= 0) hours = _calcHours(bH, bM, wH, wM);
      return SleepEntry(
        id: (raw['id'] ?? '').toString(),
        date: DateTime.tryParse((raw['date'] ?? '').toString()) ??
            DateTime.now(),
        hours: hours,
        quality: (raw['quality'] ?? 'Fair').toString(),
        qualityIndex: (raw['qualityIndex'] as num?)?.toInt() ?? 2,
        bedtimeHour: bH,
        bedtimeMinute: bM,
        wakeHour: wH,
        wakeMinute: wM,
      );
    } catch (_) {
      return null;
    }
  }
}

class SleepService {
  static const _boxName = 'sleep_logs';
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static List<SleepEntry> getAllLogs() {
    final entries = <SleepEntry>[];
    for (final v in _box.values) {
      final entry = SleepEntry.tryFromMap(v);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> addLog(SleepEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  static Future<void> updateLog(SleepEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteLog(String id) async {
    await _box.delete(id);
  }
}
