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
  })  : goals = goals ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  // Update user info from onboarding data
  void updateFromOnboarding({
    String? gender,
    String? weight,
    String? height,
    List<String>? goals,
  }) {
    if (gender != null) this.gender = gender;
    if (weight != null) this.weight = weight;
    if (height != null) this.height = height;
    if (goals != null) this.goals = goals;
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

  bool get isOnboardingComplete {
    return weight != null && height != null && goals.isNotEmpty;
  }

  bool get hasNutritionGoals {
    return nutritionGoal != null && targetCalories != null;
  }
}

