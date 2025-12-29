import 'package:hive_ce/hive.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';

class WorkoutService {
  static const String _boxName = 'workoutsBox';
  static Box<Workout>? _workoutBox;

  // Initialize the Hive box
  static Future<void> init() async {
    _workoutBox = await Hive.openBox<Workout>(_boxName);
  }

  // Create a new workout
  static Future<Workout> createWorkout({String? notes}) async {
    if (_workoutBox == null) {
      throw Exception('WorkoutService not initialized. Call init() first.');
    }

    final workout = Workout(notes: notes);
    await _workoutBox!.add(workout);
    return workout;
  }

  // Get current active workout (not completed)
  static Workout? getActiveWorkout() {
    if (_workoutBox == null) {
      throw Exception('WorkoutService not initialized. Call init() first.');
    }

    try {
      return _workoutBox!.values.firstWhere(
        (workout) => !workout.isCompleted,
      );
    } catch (e) {
      return null;
    }
  }

  // Add exercise to a workout
  static Future<void> addExerciseToWorkout(
    Workout workout,
    String exerciseName, {
    String? notes,
    String exerciseType = 'weight', // 'weight' or 'duration'
  }) async {
    final exercise = Exercise(
      name: exerciseName,
      notes: notes,
      exerciseType: exerciseType,
    );
    workout.addExercise(exercise);
    await workout.save();
  }

  // Add set to an exercise (weight-based)
  static Future<void> addSetToExercise(
    Workout workout,
    String exerciseName,
    int reps,
    double? weight, {
    int? restTimeSeconds,
    String? exerciseType,
  }) async {
    // Find or create exercise
    Exercise? exercise;
    try {
      exercise = workout.exercises.lastWhere(
        (e) => e.name == exerciseName,
      );
    } catch (e) {
      // Exercise doesn't exist, create it
      exercise = Exercise(
        name: exerciseName,
        exerciseType: exerciseType ?? 'weight',
      );
      workout.addExercise(exercise);
    }

    // Determine set number
    final setNumber = exercise.sets.length + 1;

    // Create set
    final set = ExerciseSet(
      setNumber: setNumber,
      reps: reps,
      weight: weight,
      isBodyweight: weight == null,
      restTimeSeconds: restTimeSeconds,
    );

    exercise.addSet(set);
    await workout.save();
  }

  // Add duration-based set to an exercise (cardio)
  static Future<void> addDurationSetToExercise(
    Workout workout,
    String exerciseName,
    int durationSeconds, {
    int? restTimeSeconds,
  }) async {
    // Find or create exercise
    Exercise? exercise;
    try {
      exercise = workout.exercises.lastWhere(
        (e) => e.name == exerciseName,
      );
    } catch (e) {
      // Exercise doesn't exist, create it
      exercise = Exercise(
        name: exerciseName,
        exerciseType: 'duration',
      );
      workout.addExercise(exercise);
    }

    // Determine set number
    final setNumber = exercise.sets.length + 1;

    // Create duration-based set
    final set = ExerciseSet(
      setNumber: setNumber,
      durationSeconds: durationSeconds,
      restTimeSeconds: restTimeSeconds,
    );

    exercise.addSet(set);
    await workout.save();
  }

  // Complete a workout
  static Future<void> completeWorkout(Workout workout) async {
    workout.complete();
    await workout.save();
  }

  // Get all workouts
  static List<Workout> getAllWorkouts() {
    if (_workoutBox == null) {
      throw Exception('WorkoutService not initialized. Call init() first.');
    }
    return _workoutBox!.values.toList();
  }

  // Get completed workouts
  static List<Workout> getCompletedWorkouts() {
    if (_workoutBox == null) {
      throw Exception('WorkoutService not initialized. Call init() first.');
    }
    return _workoutBox!.values
        .where((workout) => workout.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first
  }

  // Get workouts in date range
  static List<Workout> getWorkoutsInRange(DateTime start, DateTime end) {
    return getCompletedWorkouts()
        .where((workout) =>
            workout.startTime.isAfter(start) &&
            workout.startTime.isBefore(end))
        .toList();
  }

  // Get workout by ID
  static Workout? getWorkoutById(String id) {
    if (_workoutBox == null) {
      throw Exception('WorkoutService not initialized. Call init() first.');
    }
    try {
      return _workoutBox!.values.firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }

  // Delete a workout
  static Future<void> deleteWorkout(Workout workout) async {
    await workout.delete();
  }

  // Get total workout count
  static int getTotalWorkoutCount() {
    return getCompletedWorkouts().length;
  }

  // Get total sets across all workouts
  static int getTotalSets() {
    return getCompletedWorkouts()
        .fold(0, (sum, workout) => sum + workout.totalSets);
  }

  // Get total reps across all workouts
  static int getTotalReps() {
    return getCompletedWorkouts()
        .fold(0, (sum, workout) => sum + workout.totalReps);
  }

  // Get total volume across all workouts
  static double getTotalVolume() {
    return getCompletedWorkouts()
        .fold(0.0, (sum, workout) => sum + workout.totalVolume);
  }

  // Get workout streak (consecutive days with workouts)
  static int getWorkoutStreak() {
    final workouts = getCompletedWorkouts();
    if (workouts.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    // Normalize to start of day
    currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

    for (var workout in workouts) {
      final workoutDate = DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      );

      if (workoutDate.isAtSameMomentAs(currentDate) ||
          workoutDate.isAtSameMomentAs(
              currentDate.subtract(Duration(days: streak)))) {
        streak++;
        currentDate = workoutDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Get most frequent exercise
  static String? getMostFrequentExercise() {
    final exercises = <String, int>{};
    
    for (var workout in getCompletedWorkouts()) {
      for (var exercise in workout.exercises) {
        exercises[exercise.name] = (exercises[exercise.name] ?? 0) + 1;
      }
    }

    if (exercises.isEmpty) return null;

    return exercises.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Clear all workouts (for testing)
  static Future<void> clearAllWorkouts() async {
    if (_workoutBox == null) {
      throw Exception('WorkoutService not initialized. Call init() first.');
    }
    await _workoutBox!.clear();
  }

  // Close the box
  static Future<void> close() async {
    await _workoutBox?.close();
  }
}

