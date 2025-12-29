import 'package:hive_ce/hive.dart';
import '../models/food_entry.dart';
import '../models/daily_nutrition.dart';

class NutritionService {
  static const String _dailyNutritionBox = 'daily_nutrition';
  
  Box<DailyNutrition>? _nutritionBox;

  // Initialize service
  Future<void> initialize() async {
    _nutritionBox = await Hive.openBox<DailyNutrition>(_dailyNutritionBox);
  }

  // Get today's nutrition data
  DailyNutrition getTodayNutrition(int calorieGoal) {
    final today = _normalizeDate(DateTime.now());
    DailyNutrition? existing;
    
    try {
      existing = _nutritionBox?.values.firstWhere(
        (nutrition) => _isSameDay(nutrition.date, today),
      );
    } catch (e) {
      // No existing nutrition for today
      existing = null;
    }
    
    if (existing == null) {
      existing = DailyNutrition(date: today, calorieGoal: calorieGoal);
      _nutritionBox?.add(existing);
    } else {
      // Update goal if it has changed
      if (existing.calorieGoal != calorieGoal) {
        existing.calorieGoal = calorieGoal;
        existing.save();
      }
    }
    
    return existing;
  }

  // Get nutrition for specific date (by string key)
  Future<DailyNutrition?> getNutritionForDate(String dateKey) async {
    // Parse date key format: yyyy-MM-dd
    final parts = dateKey.split('-');
    if (parts.length != 3) return null;
    
    try {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      
      return _getNutritionForDateTime(date);
    } catch (e) {
      return null;
    }
  }

  // Get nutrition for specific DateTime
  DailyNutrition? _getNutritionForDateTime(DateTime date) {
    final normalized = _normalizeDate(date);
    try {
      return _nutritionBox?.values.firstWhere(
        (nutrition) => _isSameDay(nutrition.date, normalized),
      );
    } catch (e) {
      return null;
    }
  }

  // Log a food entry
  Future<void> logFood(FoodEntry entry, int calorieGoal) async {
    final today = getTodayNutrition(calorieGoal);
    today.entries.add(entry);
    await today.save();
  }

  // Delete a food entry
  Future<void> deleteFood(String entryId, int calorieGoal) async {
    final today = getTodayNutrition(calorieGoal);
    today.entries.removeWhere((e) => e.id == entryId);
    await today.save();
  }

  // Update calorie goal for today
  Future<void> updateCalorieGoal(int newGoal) async {
    final today = getTodayNutrition(newGoal);
    today.calorieGoal = newGoal;
    await today.save();
  }

  // Get all nutrition records (for history)
  List<DailyNutrition> getAllNutrition() {
    return _nutritionBox?.values.toList() ?? [];
  }

  // Get nutrition records for a date range
  List<DailyNutrition> getNutritionInRange(DateTime start, DateTime end) {
    final normalizedStart = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);
    
    return _nutritionBox?.values.where((nutrition) {
      return nutrition.date.isAfter(normalizedStart.subtract(const Duration(days: 1))) &&
          nutrition.date.isBefore(normalizedEnd.add(const Duration(days: 1)));
    }).toList() ?? [];
  }

  // Helper: Normalize date to midnight
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Helper: Check if same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Clear all data (for testing or reset)
  Future<void> clearAll() async {
    await _nutritionBox?.clear();
  }
}

