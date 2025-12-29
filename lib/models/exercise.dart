import 'package:hive_ce/hive.dart';
import 'exercise_set.dart';

part 'exercise.g.dart';

enum ExerciseType {
  weight, // Traditional weight/resistance training
  duration, // Time-based (cardio, planks, etc.)
}

@HiveType(typeId: 2)
class Exercise extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // e.g., "bench_press", "squat", "running", "cycling"

  @HiveField(2)
  List<ExerciseSet> sets;

  @HiveField(3)
  DateTime startedAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  String exerciseType; // 'weight' or 'duration'

  Exercise({
    String? id,
    required this.name,
    List<ExerciseSet>? sets,
    DateTime? startedAt,
    this.completedAt,
    this.notes,
    this.exerciseType = 'weight', // default to weight-based
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        sets = sets ?? [],
        startedAt = startedAt ?? DateTime.now();

  // Check if this is a weight-based exercise
  bool get isWeightBased => exerciseType == 'weight';

  // Check if this is a duration-based exercise
  bool get isDurationBased => exerciseType == 'duration';

  // Add a set to this exercise
  void addSet(ExerciseSet set) {
    sets.add(set);
  }

  // Get total volume (reps × weight) for weighted exercises
  double get totalVolume {
    if (!isWeightBased) return 0.0;
    return sets
        .where((set) => !set.isBodyweight && set.weight != null)
        .fold(0.0, (sum, set) => sum + (set.reps * set.weight!));
  }

  // Get total duration for duration-based exercises
  int get totalDurationSeconds {
    if (!isDurationBased) return 0;
    return sets
        .where((set) => set.durationSeconds != null)
        .fold(0, (sum, set) => sum + set.durationSeconds!);
  }

  // Get formatted total duration
  String get formattedTotalDuration {
    if (!isDurationBased) return 'N/A';
    final duration = Duration(seconds: totalDurationSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  // Get total reps
  int get totalReps {
    if (!isWeightBased) return 0;
    return sets.fold(0, (sum, set) => sum + set.reps);
  }

  // Get total sets
  int get totalSets => sets.length;

  // Get formatted exercise name
  String get displayName {
    return name.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  String toString() {
    if (isDurationBased) {
      return '$displayName: $totalSets sets, $formattedTotalDuration total';
    }
    return '$displayName: $totalSets sets, $totalReps reps';
  }
}

