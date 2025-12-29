import 'dart:convert';
import 'package:http/http.dart' as http;
import '../stores/coach_chat_store.dart';
import '../stores/nutrition_store.dart';
import '../services/workout_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/macro_calculator.dart';

class CoachChatService {
  static const String baseUrl = 'https://echelon-fastapi.fly.dev';
  final AuthService _authService;

  CoachChatService(this._authService);

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = _authService.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Send a message to the coach chat endpoint
  /// Returns the assistant's response text
  Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    List<Map<String, dynamic>>? workoutHistory,
    List<Map<String, dynamic>>? nutritionHistory,
  }) async {
    try {
      final payload = {
        'message': userMessage,
        'conversation_history': conversationHistory,
      };

      // Add workout history if provided
      if (workoutHistory != null) {
        payload['workout_history'] = workoutHistory;
      }

      if (nutritionHistory != null) {
        payload['nutrition_history'] = nutritionHistory;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat/coach'),
        headers: _getHeaders(),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['response'] as String;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's workout history formatted for API
  List<Map<String, dynamic>> getWorkoutHistory({int? limit}) {
    final workouts = WorkoutService.getCompletedWorkouts();
    
    // Limit if specified
    final workoutsToInclude = limit != null && workouts.length > limit
        ? workouts.sublist(0, limit)
        : workouts;

    return workoutsToInclude.map((workout) {
      return {
        'id': workout.id,
        'date': workout.startTime.toIso8601String(),
        'duration_minutes': workout.duration.inMinutes,
        'exercises': workout.exercises.map((exercise) {
          return {
            'name': exercise.name,
            'display_name': exercise.displayName,
            'type': exercise.exerciseType,
            'sets': exercise.sets.length,
            'total_reps': exercise.isWeightBased ? exercise.totalReps : null,
            'total_volume': exercise.isWeightBased ? exercise.totalVolume : null,
            'total_duration_seconds': exercise.isDurationBased ? exercise.totalDurationSeconds : null,
          };
        }).toList(),
      };
    }).toList();
  }

  /// Get today's nutrition data formatted for API
  Map<String, dynamic>? getTodaysNutrition(NutritionStore nutritionStore) {
    if (!nutritionStore.hasSetGoals) {
      return null;
    }

    final macroTargets = MacroCalculator.calculateTargets();
    final goals = UserService.getNutritionGoals();
    
    return {
      'goal': goals?['goal'],
      'calories': {
        'consumed': nutritionStore.totalCalories,
        'target': nutritionStore.targetCalories,
        'remaining': nutritionStore.remaining,
      },
      'macros': {
        'protein': {
          'consumed': nutritionStore.totalProtein,
          'target': macroTargets['protein'],
          'remaining': (macroTargets['protein']! - nutritionStore.totalProtein).clamp(0, double.infinity),
        },
        'carbs': {
          'consumed': nutritionStore.totalCarbs,
          'target': macroTargets['carbs'],
          'remaining': (macroTargets['carbs']! - nutritionStore.totalCarbs).clamp(0, double.infinity),
        },
        'fats': {
          'consumed': nutritionStore.totalFats,
          'target': macroTargets['fats'],
          'remaining': (macroTargets['fats']! - nutritionStore.totalFats).clamp(0, double.infinity),
        },
      },
      'meals_logged': nutritionStore.entries.length,
      'recent_meals': nutritionStore.entries.take(5).map((entry) {
        return {
          'name': entry.name,
          'calories': entry.calories,
          'protein': entry.protein,
          'carbs': entry.carbs,
          'fats': entry.fats,
          'time': entry.timeFormatted,
        };
      }).toList(),
    };
  }

  /// Send a message using the store (convenience method)
  /// Automatically handles adding messages to the store
  static Future<void> sendMessageWithStore({
    required CoachChatService service,
    required String userMessage,
    required CoachChatStore store,
    NutritionStore? nutritionStore,
    bool includeWorkoutHistory = true,
    bool includeNutritionHistory = true,
    int? workoutHistoryLimit = 10,
  }) async {
    // Add user message to store
    store.addUserMessage(userMessage);
    
    // Set loading state
    store.setLoading(true);
    store.clearError();

    try {
      // Get conversation history (excluding the message we just added)
      final history = store.getSimpleHistory();
      
      // Get workout history if requested
      List<Map<String, dynamic>>? workoutHistory;
      if (includeWorkoutHistory) {
        workoutHistory = service.getWorkoutHistory(limit: workoutHistoryLimit);
      }
      
      // Get today's nutrition if requested
      Map<String, dynamic>? nutritionData;
      if (includeNutritionHistory && nutritionStore != null) {
        nutritionData = service.getTodaysNutrition(nutritionStore);
        if (nutritionData != null) {
        }
      }
      
      // Send to API
      final response = await service.sendMessage(
        userMessage: userMessage,
        conversationHistory: history.sublist(0, history.length - 1),
        workoutHistory: workoutHistory,
        nutritionHistory: nutritionData != null ? [nutritionData] : null,
      );

      // Add agent response to store
      store.addAgentMessage(response);
    } catch (e) {
      // Set error state
      store.setError('Failed to get response from coach. Please try again.');
    } finally {
      // Clear loading state
      store.setLoading(false);
    }
  }
}
