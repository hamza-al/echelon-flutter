import 'package:hive_ce/hive.dart';
import '../models/user.dart';

class UserService {
  static const String _boxName = 'userBox';
  static const String _userKey = 'currentUser';

  static Box<User>? _userBox;

  // Initialize the Hive box
  static Future<void> init() async {
    _userBox = await Hive.openBox<User>(_boxName);
  }

  // Get the current user (or create if doesn't exist)
  static User getCurrentUser() {
    if (_userBox == null) {
      throw Exception('UserService not initialized. Call init() first.');
    }

    var user = _userBox!.get(_userKey);
    if (user == null) {
      user = User();
      _userBox!.put(_userKey, user);
    }
    return user;
  }

  // Save user data
  static Future<void> saveUser(User user) async {
    if (_userBox == null) {
      throw Exception('UserService not initialized. Call init() first.');
    }
    await _userBox!.put(_userKey, user);
  }

  // Update user from onboarding
  static Future<void> updateFromOnboarding({
    String? gender,
    String? weight,
    String? height,
    List<String>? goals,
  }) async {
    final user = getCurrentUser();
    user.updateFromOnboarding(
      gender: gender,
      weight: weight,
      height: height,
      goals: goals,
    );
    await saveUser(user);
  }

  // Update subscription status
  static Future<void> updateSubscriptionStatus(bool isPaid) async {
    final user = getCurrentUser();
    user.updateSubscriptionStatus(isPaid);
    await saveUser(user);
  }

  // Check if user has completed onboarding
  static bool hasCompletedOnboarding() {
    final user = getCurrentUser();
    return user.isOnboardingComplete;
  }

  // Check if user has paid subscription
  static bool hasPaidSubscription() {
    final user = getCurrentUser();
    return user.hasPaidSubscription;
  }

  // Update nutrition goals
  static Future<void> updateNutritionGoals({
    required String goal,
    required int calories,
  }) async {
    final user = getCurrentUser();
    user.updateNutritionGoals(goal: goal, calories: calories);
    await saveUser(user);
  }

  // Get nutrition goals
  static Map<String, dynamic>? getNutritionGoals() {
    final user = getCurrentUser();
    if (user.hasNutritionGoals) {
      return {
        'goal': user.nutritionGoal,
        'calories': user.targetCalories,
      };
    }
    return null;
  }

  // Clear all user data (for testing/logout)
  static Future<void> clearUserData() async {
    if (_userBox == null) {
      throw Exception('UserService not initialized. Call init() first.');
    }
    await _userBox!.clear();
  }

  // Close the box (call on app termination)
  static Future<void> close() async {
    await _userBox?.close();
  }
}

