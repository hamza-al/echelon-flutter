import 'package:flutter/foundation.dart';

/// Message in the workout conversation
class WorkoutMessage {
  final String userTranscript;
  final String agentResponse;
  final DateTime timestamp;

  WorkoutMessage({
    required this.userTranscript,
    required this.agentResponse,
    required this.timestamp,
  });
}

/// Store for managing active workout state
/// Similar to Pinia stores - provides reactive state management
class ActiveWorkoutStore extends ChangeNotifier {
  String? _activeWorkoutId;
  final List<WorkoutMessage> _conversation = [];
  DateTime? _workoutStartTime;

  // Getters
  String? get activeWorkoutId => _activeWorkoutId;
  List<WorkoutMessage> get conversation => List.unmodifiable(_conversation);
  DateTime? get workoutStartTime => _workoutStartTime;
  bool get hasActiveWorkout => _activeWorkoutId != null;
  int get messageCount => _conversation.length;

  /// Start a new workout session
  void startWorkout(String workoutId) {
    _activeWorkoutId = workoutId;
    _workoutStartTime = DateTime.now();
    _conversation.clear();
    notifyListeners();
  }

  /// Add a message to the conversation
  void addMessage({
    required String userTranscript,
    required String agentResponse,
  }) {
    _conversation.add(WorkoutMessage(
      userTranscript: userTranscript,
      agentResponse: agentResponse,
      timestamp: DateTime.now(),
    ));
    
    notifyListeners();
  }

  /// End the workout and clear all state
  void endWorkout() {
    _activeWorkoutId = null;
    _workoutStartTime = null;
    _conversation.clear();
    notifyListeners();
  }

  /// Get the full conversation as a list for sending to backend
  List<Map<String, dynamic>> getConversationHistory() {
    return _conversation.map((msg) => {
      'user_transcript': msg.userTranscript,
      'agent_response': msg.agentResponse,
      'timestamp': msg.timestamp.toIso8601String(),
    }).toList();
  }
}

