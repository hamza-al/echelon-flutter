import 'dart:async';
import 'package:flutter/foundation.dart';

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

class ActiveWorkoutStore extends ChangeNotifier {
  String? _activeWorkoutId;
  String? _workoutLabel;
  final List<WorkoutMessage> _conversation = [];
  DateTime? _workoutStartTime;
  int _setsLogged = 0;

  // Shared rest timer state
  int _restTotal = 0;
  int _restRemaining = 0;
  bool _restRunning = false;
  Timer? _restTimer;

  // --- Workout getters ---
  String? get activeWorkoutId => _activeWorkoutId;
  String? get workoutLabel => _workoutLabel;
  List<WorkoutMessage> get conversation => List.unmodifiable(_conversation);
  DateTime? get workoutStartTime => _workoutStartTime;
  bool get hasActiveWorkout => _activeWorkoutId != null;
  int get messageCount => _conversation.length;
  int get setsLogged => _setsLogged;

  // --- Timer getters ---
  int get restTotal => _restTotal;
  int get restRemaining => _restRemaining;
  bool get restRunning => _restRunning;
  bool get hasActiveRest => _restRunning || _restRemaining > 0;
  double get restProgress =>
      _restTotal > 0 ? 1.0 - (_restRemaining / _restTotal) : 0.0;

  String get workoutElapsed {
    if (_workoutStartTime == null) return '';
    final d = DateTime.now().difference(_workoutStartTime!);
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void startWorkout(String workoutId, {String? label}) {
    _activeWorkoutId = workoutId;
    _workoutLabel = label;
    _workoutStartTime = DateTime.now();
    _setsLogged = 0;
    _conversation.clear();
    notifyListeners();
  }

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

  void incrementSets([int count = 1]) {
    _setsLogged += count;
    notifyListeners();
  }

  void endWorkout() {
    _activeWorkoutId = null;
    _workoutLabel = null;
    _workoutStartTime = null;
    _setsLogged = 0;
    _conversation.clear();
    cancelRest();
    notifyListeners();
  }

  // --- Shared rest timer ---

  void startRest(int durationSeconds) {
    _restTimer?.cancel();
    _restTotal = durationSeconds;
    _restRemaining = durationSeconds;
    _restRunning = true;
    notifyListeners();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining > 0) {
        _restRemaining--;
        notifyListeners();
      } else {
        _restTimer?.cancel();
        _restRunning = false;
        notifyListeners();
      }
    });
  }

  void cancelRest() {
    _restTimer?.cancel();
    _restTotal = 0;
    _restRemaining = 0;
    _restRunning = false;
    notifyListeners();
  }

  void skipRest() {
    _restTimer?.cancel();
    _restRemaining = 0;
    _restRunning = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> getConversationHistory() {
    return _conversation
        .map((msg) => {
              'user_transcript': msg.userTranscript,
              'agent_response': msg.agentResponse,
              'timestamp': msg.timestamp.toIso8601String(),
            })
        .toList();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}
