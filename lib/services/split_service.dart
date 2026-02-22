import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/workout_split.dart';

class SplitService {
  static const String _boxName = 'split_box';
  static const String _splitKey = 'user_split';

  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Box _getBox() {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SplitService not initialized');
    }
    return _box!;
  }

  // Get the user's current split (default to PPL if none set)
  static WorkoutSplit getCurrentSplit() {
    try {
      final box = _getBox();
      final splitData = box.get(_splitKey) as Map?;
      
      if (splitData == null) {
        // Default to Push/Pull/Legs
        return WorkoutSplit.pushPullLegs();
      }
      
      return WorkoutSplit(
        splitType: splitData['splitType'] as String,
        dayNames: List<String>.from(splitData['dayNames'] as List),
      );
    } catch (e) {
      return WorkoutSplit.pushPullLegs();
    }
  }

  // Save the user's split selection
  static Future<void> setSplit(WorkoutSplit split) async {
    try {
      final box = _getBox();
      await box.put(_splitKey, {
        'splitType': split.splitType,
        'dayNames': split.dayNames,
      });
    } catch (e) {
      // Fail silently
    }
  }

  // Get today's workout based on current split
  static String getTodaysWorkout() {
    final split = getCurrentSplit();
    final now = DateTime.now();
    // Monday = 1, Sunday = 7, convert to 0-indexed (Monday = 0)
    final dayOfWeek = now.weekday - 1;
    return split.getDayWorkout(dayOfWeek);
  }

  // Get workout for a specific date
  static String getWorkoutForDate(DateTime date) {
    final split = getCurrentSplit();
    final dayOfWeek = date.weekday - 1;
    return split.getDayWorkout(dayOfWeek);
  }

  // Get the week's schedule starting from today
  static List<Map<String, dynamic>> getWeekSchedule() {
    final split = getCurrentSplit();
    final now = DateTime.now();
    final schedule = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayOfWeek = date.weekday - 1;
      schedule.add({
        'date': date,
        'dayName': _getDayName(date.weekday),
        'workout': split.getDayWorkout(dayOfWeek),
        'isToday': i == 0,
      });
    }

    return schedule;
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
