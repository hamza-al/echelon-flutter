import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'food_entry.dart';

part 'daily_nutrition.g.dart';

@HiveType(typeId: 5)
class DailyNutrition extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<FoodEntry> entries;

  @HiveField(3)
  int calorieGoal;

  DailyNutrition({
    String? id,
    required this.date,
    List<FoodEntry>? entries,
    this.calorieGoal = 2000,
  })  : id = id ?? const Uuid().v4(),
        entries = entries ?? [];

  // Computed properties
  int get totalCalories => entries.fold(0, (sum, e) => sum + e.calories);
  
  double get totalProtein => entries.fold(0.0, (sum, e) => sum + (e.protein ?? 0));
  
  double get totalCarbs => entries.fold(0.0, (sum, e) => sum + (e.carbs ?? 0));
  
  double get totalFats => entries.fold(0.0, (sum, e) => sum + (e.fats ?? 0));
  
  int get remaining => calorieGoal - totalCalories;
  
  double get progress => calorieGoal > 0 ? (totalCalories / calorieGoal).clamp(0.0, 2.0) : 0.0;
  
  bool get isOverGoal => totalCalories > calorieGoal;
  
  int get entryCount => entries.length;
}

