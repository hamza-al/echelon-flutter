import '../services/user_service.dart';

class MacroCalculator {
  // Calculate macro targets based on weight and nutrition goal,
  // or use custom values if the user has set them.
  static Map<String, double> calculateTargets() {
    final user = UserService.getCurrentUser();
    final goals = UserService.getNutritionGoals();

    // Use custom macros if set
    if (user.customProtein != null || user.customCarbs != null || user.customFats != null) {
      return {
        'protein': user.customProtein ?? _defaultProtein(user, goals),
        'carbs': user.customCarbs ?? _defaultCarbs(user),
        'fats': user.customFats ?? _defaultFats(user, goals),
      };
    }
    
    return {
      'protein': _defaultProtein(user, goals),
      'carbs': _defaultCarbs(user),
      'fats': _defaultFats(user, goals),
    };
  }

  static double _parseWeight(dynamic user) {
    if (user.weight == null) return 170;
    final weightStr = (user.weight as String).replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(weightStr) ?? 170;
  }

  static double _defaultProtein(dynamic user, Map<String, dynamic>? goals) {
    if (user.weight == null || goals == null) return 0;
    return _parseWeight(user); // 1g per lb
  }

  static double _defaultCarbs(dynamic user) {
    if (user.weight == null) return 0;
    return _parseWeight(user) * 2.25;
  }

  static double _defaultFats(dynamic user, Map<String, dynamic>? goals) {
    if (user.weight == null || goals == null) return 0;
    final weight = _parseWeight(user);
    final nutritionGoal = goals['goal'] as String?;
    switch (nutritionGoal) {
      case 'cut':
        return weight * 0.35;
      case 'bulk':
        return weight * 0.55;
      case 'maintain':
      default:
        return weight * 0.45;
    }
  }
}

