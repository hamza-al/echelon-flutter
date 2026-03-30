class OnboardingData {
  String? name;
  int? age;
  String? gender;
  String? weight;
  String? height;
  List<String> goals = [];
  String? nutritionGoal;
  int targetCalories = 2000;

  OnboardingData({
    this.name,
    this.age,
    this.gender,
    this.weight,
    this.height,
    List<String>? goals,
    this.nutritionGoal,
    this.targetCalories = 2000,
  }) : goals = goals ?? [];

  bool get isComplete {
    return name != null &&
        weight != null &&
        height != null &&
        goals.isNotEmpty &&
        nutritionGoal != null;
  }
}
