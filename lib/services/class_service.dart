import 'package:hive_ce/hive.dart';
import '../models/class_entry.dart';

class ClassService {
  static const String _boxName = 'classEntriesBox';
  static Box<ClassEntry>? _classBox;

  static Future<void> init() async {
    _classBox = await Hive.openBox<ClassEntry>(_boxName);
  }

  static Future<void> logClass(ClassEntry entry) async {
    if (_classBox == null) {
      throw Exception('ClassService not initialized. Call init() first.');
    }
    await _classBox!.add(entry);
  }

  static List<ClassEntry> getAllClasses() {
    if (_classBox == null) {
      throw Exception('ClassService not initialized. Call init() first.');
    }
    return _classBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static List<ClassEntry> getClassesForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return getAllClasses().where((entry) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      return entryDate.isAtSameMomentAs(normalized);
    }).toList();
  }

  static List<ClassEntry> getClassesInRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    return getAllClasses().where((entry) {
      return entry.timestamp.isAfter(normalizedStart) &&
          entry.timestamp.isBefore(normalizedEnd);
    }).toList();
  }

  static Future<void> deleteClass(String id) async {
    if (_classBox == null) {
      throw Exception('ClassService not initialized. Call init() first.');
    }
    final entry = _classBox!.values.where((e) => e.id == id).firstOrNull;
    if (entry != null) {
      await entry.delete();
    }
  }

  static Future<void> updateClass(ClassEntry updated) async {
    if (_classBox == null) {
      throw Exception('ClassService not initialized. Call init() first.');
    }
    final existing = _classBox!.values.where((e) => e.id == updated.id).firstOrNull;
    if (existing != null) {
      existing.className = updated.className;
      existing.durationMinutes = updated.durationMinutes;
      existing.notes = updated.notes;
      await existing.save();
    }
  }

  static int getTotalClassCount() {
    return getAllClasses().length;
  }

  /// Returns dates that had a class logged (for streak calculation)
  static Set<DateTime> getClassDates() {
    return getAllClasses().map((e) => DateTime(
      e.timestamp.year,
      e.timestamp.month,
      e.timestamp.day,
    )).toSet();
  }
}
