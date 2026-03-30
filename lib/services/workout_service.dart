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

  static Future<void> seedMockData() async {
    if (_workoutBox == null) throw Exception('WorkoutService not initialized.');
    if (_workoutBox!.isNotEmpty) return;

    final now = DateTime.now();

    Workout make(DateTime start, int durationMin, List<Exercise> exercises) {
      final w = Workout(
        startTime: start,
        exercises: exercises,
        isCompleted: true,
      );
      w.endTime = start.add(Duration(minutes: durationMin));
      return w;
    }

    Exercise ex(String name, List<ExerciseSet> sets,
        {String type = 'weight'}) {
      return Exercise(name: name, sets: sets, exerciseType: type);
    }

    ExerciseSet ws(int setNum, int reps, double weight) {
      return ExerciseSet(
          setNumber: setNum, reps: reps, weight: weight, isBodyweight: false);
    }

    ExerciseSet bw(int setNum, int reps) {
      return ExerciseSet(
          setNumber: setNum, reps: reps, isBodyweight: true);
    }

    ExerciseSet dur(int setNum, int seconds) {
      return ExerciseSet(setNumber: setNum, durationSeconds: seconds);
    }

    final workouts = <Workout>[
      make(now.subtract(const Duration(hours: 3)), 52, [
        ex('bench_press', [ws(1, 10, 185), ws(2, 8, 205), ws(3, 6, 225), ws(4, 5, 225)]),
        ex('overhead_press', [ws(1, 10, 95), ws(2, 8, 105), ws(3, 8, 105)]),
        ex('incline_dumbbell_press', [ws(1, 12, 60), ws(2, 10, 65), ws(3, 10, 65)]),
        ex('tricep_dips', [bw(1, 15), bw(2, 12), bw(3, 10)]),
      ]),
      make(now.subtract(const Duration(days: 1, hours: 5)), 58, [
        ex('deadlift', [ws(1, 8, 275), ws(2, 6, 315), ws(3, 5, 335), ws(4, 3, 365)]),
        ex('barbell_row', [ws(1, 10, 155), ws(2, 8, 175), ws(3, 8, 175)]),
        ex('pull_ups', [bw(1, 12), bw(2, 10), bw(3, 8)]),
        ex('barbell_curl', [ws(1, 12, 65), ws(2, 10, 75), ws(3, 10, 75)]),
      ]),
      make(now.subtract(const Duration(days: 3, hours: 2)), 48, [
        ex('squat', [ws(1, 10, 225), ws(2, 8, 255), ws(3, 6, 275), ws(4, 5, 275)]),
        ex('leg_press', [ws(1, 12, 360), ws(2, 10, 410), ws(3, 10, 410)]),
        ex('lunges', [ws(1, 12, 40), ws(2, 12, 40), ws(3, 10, 50)]),
      ]),
      make(now.subtract(const Duration(days: 5, hours: 4)), 45, [
        ex('bench_press', [ws(1, 10, 185), ws(2, 8, 205), ws(3, 7, 215)]),
        ex('cable_fly', [ws(1, 15, 30), ws(2, 12, 35), ws(3, 12, 35)]),
        ex('lateral_raise', [ws(1, 15, 20), ws(2, 12, 25), ws(3, 12, 25)]),
      ]),
      make(now.subtract(const Duration(days: 7, hours: 6)), 55, [
        ex('barbell_row', [ws(1, 10, 155), ws(2, 8, 175), ws(3, 6, 185)]),
        ex('lat_pulldown', [ws(1, 12, 130), ws(2, 10, 145), ws(3, 10, 145)]),
        ex('face_pulls', [ws(1, 15, 40), ws(2, 15, 45), ws(3, 15, 45)]),
        ex('hammer_curl', [ws(1, 12, 30), ws(2, 10, 35), ws(3, 10, 35)]),
      ]),
      make(now.subtract(const Duration(days: 10, hours: 3)), 50, [
        ex('squat', [ws(1, 10, 215), ws(2, 8, 245), ws(3, 6, 265)]),
        ex('romanian_deadlift', [ws(1, 10, 185), ws(2, 8, 205), ws(3, 8, 205)]),
        ex('leg_curl', [ws(1, 12, 90), ws(2, 10, 100), ws(3, 10, 100)]),
        ex('plank', [dur(1, 60), dur(2, 60), dur(3, 45)], type: 'duration'),
      ]),
    ];

    for (final w in workouts) {
      await _workoutBox!.add(w);
    }
  }

  // Close the box
  static Future<void> close() async {
    await _workoutBox?.close();
  }
}

