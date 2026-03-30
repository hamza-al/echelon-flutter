import 'package:hive_ce/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String? gender;

  @HiveField(1)
  String? weight;

  @HiveField(2)
  String? height;

  @HiveField(3)
  List<String> goals;

  @HiveField(4)
  bool hasPaidSubscription;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  DateTime? lastUpdated;

  @HiveField(7)
  int longestStreak;

  @HiveField(8)
  String? nutritionGoal; // 'cut', 'bulk', 'maintain'

  @HiveField(9)
  int? targetCalories;

  @HiveField(10)
  double? customProtein;

  @HiveField(11)
  double? customCarbs;

  @HiveField(12)
  double? customFats;

  @HiveField(13)
  String? name;

  @HiveField(14)
  int? age;

  @HiveField(15)
  String? preferredWorkoutTime;

  @HiveField(16)
  int? bedtimeHour;

  @HiveField(17)
  int? bedtimeMinute;

  @HiveField(18)
  int? wakeHour;

  @HiveField(19)
  int? wakeMinute;

  User({
    this.gender,
    this.weight,
    this.height,
    List<String>? goals,
    this.hasPaidSubscription = false,
    DateTime? createdAt,
    DateTime? lastUpdated,
    this.longestStreak = 0,
    this.nutritionGoal,
    this.targetCalories,
    this.customProtein,
    this.customCarbs,
    this.customFats,
    this.name,
    this.age,
    this.preferredWorkoutTime,
    this.bedtimeHour,
    this.bedtimeMinute,
    this.wakeHour,
    this.wakeMinute,
  })  : goals = goals ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  void updateFromOnboarding({
    String? name,
    int? age,
    String? gender,
    String? weight,
    String? height,
    List<String>? goals,
    String? preferredWorkoutTime,
    int? bedtimeHour,
    int? bedtimeMinute,
    int? wakeHour,
    int? wakeMinute,
  }) {
    if (name != null) this.name = name;
    if (age != null) this.age = age;
    if (gender != null) this.gender = gender;
    if (weight != null) this.weight = weight;
    if (height != null) this.height = height;
    if (goals != null) this.goals = goals;
    if (preferredWorkoutTime != null) this.preferredWorkoutTime = preferredWorkoutTime;
    if (bedtimeHour != null) this.bedtimeHour = bedtimeHour;
    if (bedtimeMinute != null) this.bedtimeMinute = bedtimeMinute;
    if (wakeHour != null) this.wakeHour = wakeHour;
    if (wakeMinute != null) this.wakeMinute = wakeMinute;
    lastUpdated = DateTime.now();
  }

  // Update subscription status
  void updateSubscriptionStatus(bool isPaid) {
    hasPaidSubscription = isPaid;
    lastUpdated = DateTime.now();
  }

  // Update longest streak if current is greater
  void updateLongestStreak(int currentStreak) {
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      lastUpdated = DateTime.now();
    }
  }

  // Update nutrition goals
  void updateNutritionGoals({
    required String goal,
    required int calories,
  }) {
    nutritionGoal = goal;
    targetCalories = calories;
    lastUpdated = DateTime.now();
  }

  // Update custom macro targets (null = use auto-calculated defaults)
  void updateCustomMacros({
    double? protein,
    double? carbs,
    double? fats,
  }) {
    customProtein = protein;
    customCarbs = carbs;
    customFats = fats;
    lastUpdated = DateTime.now();
  }

  bool get isOnboardingComplete {
    return weight != null && height != null && goals.isNotEmpty;
  }

  bool get hasNutritionGoals {
    return nutritionGoal != null && targetCalories != null;
  }
}

