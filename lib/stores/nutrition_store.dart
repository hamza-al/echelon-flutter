import 'package:flutter/foundation.dart';
import '../models/food_entry.dart';
import '../models/daily_nutrition.dart';
import '../services/nutrition_service.dart';
import '../services/user_service.dart';

class NutritionStore extends ChangeNotifier {
  final NutritionService _nutritionService;
  
  // Current day's data
  DailyNutrition? _todayNutrition;
  
  NutritionStore(this._nutritionService);

  // Getters - read from Hive User model
  String? get nutritionGoal {
    final goals = UserService.getNutritionGoals();
    return goals?['goal'];
  }
  
  int? get targetCalories {
    final goals = UserService.getNutritionGoals();
    return goals?['calories'];
  }
  
  bool get hasSetGoals {
    final goals = UserService.getNutritionGoals();
    return goals != null && goals['goal'] != null && goals['calories'] != null;
  }
  
  DailyNutrition? get todayNutrition => _todayNutrition;
  
  int get totalCalories => _todayNutrition?.totalCalories ?? 0;
  double get totalProtein => _todayNutrition?.totalProtein ?? 0;
  double get totalCarbs => _todayNutrition?.totalCarbs ?? 0;
  double get totalFats => _todayNutrition?.totalFats ?? 0;
  int get remaining => _todayNutrition?.remaining ?? (targetCalories ?? 0);
  double get progress => _todayNutrition?.progress ?? 0.0;
  bool get isOverGoal => _todayNutrition?.isOverGoal ?? false;
  List<FoodEntry> get entries => _todayNutrition?.entries ?? [];

  // Initialize
  void initialize() {
    final calories = targetCalories;
    if (calories != null) {
      _todayNutrition = _nutritionService.getTodayNutrition(calories);
    }
    notifyListeners();
  }

  // Set nutrition goals (from goal setup) - saves to Hive
  Future<void> setNutritionGoals({required String goal, required int calories}) async {
    await UserService.updateNutritionGoals(goal: goal, calories: calories);
    _todayNutrition = _nutritionService.getTodayNutrition(calories);
    
    // Ensure today's record has the correct calorie goal
    if (_todayNutrition != null && _todayNutrition!.calorieGoal != calories) {
      _todayNutrition!.calorieGoal = calories;
      await _todayNutrition!.save();
    }
    
    notifyListeners();
  }

  // Update target calories - saves to Hive
  Future<void> updateTargetCalories(int calories) async {
    final currentGoal = nutritionGoal ?? 'maintain';
    await UserService.updateNutritionGoals(goal: currentGoal, calories: calories);
    await _nutritionService.updateCalorieGoal(calories);
    _todayNutrition = _nutritionService.getTodayNutrition(calories);
    notifyListeners();
  }

  // Log food
  Future<void> logFood({
    required String name,
    required int calories,
    double? protein,
    double? carbs,
    double? fats,
  }) async {
    final targetCals = targetCalories;
    if (targetCals == null) return; // Safety check
    
    final entry = FoodEntry(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
    
    await _nutritionService.logFood(entry, targetCals);
    _todayNutrition = _nutritionService.getTodayNutrition(targetCals);
    notifyListeners();
  }

  // Delete food entry
  Future<void> deleteFood(String entryId) async {
    final targetCals = targetCalories;
    if (targetCals == null) return; // Safety check
    
    await _nutritionService.deleteFood(entryId, targetCals);
    _todayNutrition = _nutritionService.getTodayNutrition(targetCals);
    notifyListeners();
  }

  // Refresh today's data
  void refreshToday() {
    final targetCals = targetCalories;
    if (targetCals != null) {
      _todayNutrition = _nutritionService.getTodayNutrition(targetCals);
    }
    notifyListeners();
  }

  // Get nutrition for specific date
  Future<DailyNutrition?> getNutritionForDate(DateTime date) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return await _nutritionService.getNutritionForDate(dateKey);
  }

  // Get all nutrition history
  List<DailyNutrition> getAllNutrition() {
    return _nutritionService.getAllNutrition();
  }
}

