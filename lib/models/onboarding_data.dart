class OnboardingData {
  String? gender;
  String? weight;
  String? height;
  List<String> goals = [];
  String? nutritionGoal;
  int targetCalories = 2000;

  OnboardingData({
    this.gender,
    this.weight,
    this.height,
    List<String>? goals,
    this.nutritionGoal,
    this.targetCalories = 2000,
  }) : goals = goals ?? [];

  bool get isComplete {
    return weight != null &&
        height != null &&
        goals.isNotEmpty &&
        nutritionGoal != null;
  }
}

