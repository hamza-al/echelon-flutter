import 'package:hive_ce/hive.dart';

part 'exercise_set.g.dart';

@HiveType(typeId: 3)
class ExerciseSet extends HiveObject {
  @HiveField(0)
  int setNumber;

  @HiveField(1)
  int reps; // for weight-based exercises

  @HiveField(2)
  double? weight; // null for bodyweight exercises

  @HiveField(3)
  bool isBodyweight;

  @HiveField(4)
  DateTime completedAt;

  @HiveField(5)
  int? restTimeSeconds; // optional rest time in seconds

  @HiveField(6)
  int? durationSeconds; // for duration-based exercises (cardio, etc.)

  ExerciseSet({
    required this.setNumber,
    this.reps = 0,
    this.weight,
    this.isBodyweight = false,
    DateTime? completedAt,
    this.restTimeSeconds,
    this.durationSeconds,
  }) : completedAt = completedAt ?? DateTime.now();

  // Helper to get weight display string
  String get weightDisplay {
    if (isBodyweight) {
      return 'Bodyweight';
    }
    return weight != null ? '${weight!.toStringAsFixed(1)} lbs' : 'N/A';
  }

  // Helper to get duration display string
  String get durationDisplay {
    if (durationSeconds == null) return 'N/A';
    final duration = Duration(seconds: durationSeconds!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  // Helper to get set summary
  String get summary {
    // Duration-based set (cardio)
    if (durationSeconds != null) {
      return durationDisplay;
    }
    
    // Weight-based set
    if (isBodyweight) {
      return '$reps reps (bodyweight)';
    }
    return '$reps reps × ${weight!.toStringAsFixed(0)} lbs';
  }

  @override
  String toString() {
    return 'Set $setNumber: $summary';
  }
}

