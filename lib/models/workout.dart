import 'package:hive_ce/hive.dart';
import 'exercise.dart';

part 'workout.g.dart';

@HiveType(typeId: 1)
class Workout extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  List<Exercise> exercises;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  bool isCompleted;

  Workout({
    String? id,
    DateTime? startTime,
    this.endTime,
    List<Exercise>? exercises,
    this.notes,
    this.isCompleted = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        startTime = startTime ?? DateTime.now(),
        exercises = exercises ?? [];

  // Add an exercise to this workout
  void addExercise(Exercise exercise) {
    exercises.add(exercise);
  }

  // Complete the workout
  void complete() {
    isCompleted = true;
    endTime = DateTime.now();
  }

  // Get workout duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Get formatted duration
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  // Get total sets across all exercises
  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);
  }

  // Get total reps across all exercises
  int get totalReps {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalReps);
  }

  // Get total volume across all exercises
  double get totalVolume {
    return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);
  }

  // Get list of unique exercise names
  List<String> get exerciseNames {
    return exercises.map((e) => e.displayName).toSet().toList();
  }

  // Get exercise count
  int get exerciseCount => exercises.length;

  @override
  String toString() {
    return 'Workout on ${startTime.toString()}: $exerciseCount exercises, $totalSets sets';
  }
}

