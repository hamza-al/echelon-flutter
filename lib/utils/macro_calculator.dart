import '../services/user_service.dart';

class MacroCalculator {
  // Calculate macro targets based on weight and nutrition goal
  static Map<String, double> calculateTargets() {
    final user = UserService.getCurrentUser();
    final goals = UserService.getNutritionGoals();
    
    if (user.weight == null || goals == null) {
      return {
        'protein': 0,
        'carbs': 0,
        'fats': 0,
      };
    }
    
    // Parse weight (could be in format "170 lbs" or just "170")
    final weightStr = user.weight!.replaceAll(RegExp(r'[^0-9.]'), '');
    final weight = double.tryParse(weightStr) ?? 170; // Default fallback
    
    final nutritionGoal = goals['goal'] as String?;
    
    // Protein: 1g per lb of body weight
    final protein = weight;
    
    // Carbs: 2.25g per lb of body weight
    final carbs = weight * 2.25;
    
    // Fats: Based on goal
    double fats;
    switch (nutritionGoal) {
      case 'cut':
        fats = weight * 0.35; // 0.3-0.4 range, using middle
        break;
      case 'bulk':
        fats = weight * 0.55; // 0.5-0.6 range, using middle
        break;
      case 'maintain':
      default:
        fats = weight * 0.45; // 0.4-0.5 range, using middle
        break;
    }
    
    return {
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}

