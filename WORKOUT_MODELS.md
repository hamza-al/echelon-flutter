# Workout Data Models - Hive Structure

## Overview
Complete Hive database structure for managing workouts, exercises, and sets. Follows a hierarchical structure: Workout → Exercise → ExerciseSet.

## Type IDs
- `User`: typeId 0
- `Workout`: typeId 1
- `Exercise`: typeId 2
- `ExerciseSet`: typeId 3

## Model Structure

### ExerciseSet (typeId: 3)
Represents a single set within an exercise.

**Fields:**
- `setNumber` (int) - The set number (1, 2, 3, etc.)
- `reps` (int) - Number of repetitions
- `weight` (double?) - Weight in lbs (null for bodyweight)
- `isBodyweight` (bool) - Whether this is a bodyweight exercise
- `completedAt` (DateTime) - When the set was completed
- `restTimeSeconds` (int?) - Optional rest time after this set

**Computed Properties:**
- `weightDisplay` - Formatted weight string ("Bodyweight" or "X lbs")
- `summary` - "X reps × Y lbs" or "X reps (bodyweight)"

**Example:**
```dart
ExerciseSet(
  setNumber: 1,
  reps: 8,
  weight: 225.0,
  isBodyweight: false,
  restTimeSeconds: 90,
)
```

### Exercise (typeId: 2)
Represents a single exercise within a workout session.

**Fields:**
- `id` (String) - Unique identifier
- `name` (String) - Exercise name (e.g., "bench_press", "squat")
- `sets` (List<ExerciseSet>) - All sets for this exercise
- `startedAt` (DateTime) - When the exercise started
- `completedAt` (DateTime?) - When the exercise was completed
- `notes` (String?) - Optional notes

**Computed Properties:**
- `totalVolume` - Total weight × reps for all sets
- `totalReps` - Sum of all reps
- `totalSets` - Number of sets
- `displayName` - Formatted exercise name ("Bench Press")

**Methods:**
- `addSet(ExerciseSet)` - Add a set to this exercise

**Example:**
```dart
Exercise(
  name: 'bench_press',
  sets: [
    ExerciseSet(setNumber: 1, reps: 8, weight: 225.0, isBodyweight: false),
    ExerciseSet(setNumber: 2, reps: 8, weight: 225.0, isBodyweight: false),
    ExerciseSet(setNumber: 3, reps: 8, weight: 225.0, isBodyweight: false),
  ],
)
```

### Workout (typeId: 1)
Represents a complete workout session containing multiple exercises.

**Fields:**
- `id` (String) - Unique identifier
- `startTime` (DateTime) - When the workout started
- `endTime` (DateTime?) - When the workout ended
- `exercises` (List<Exercise>) - All exercises in this workout
- `notes` (String?) - Optional workout notes
- `isCompleted` (bool) - Whether the workout is completed

**Computed Properties:**
- `duration` - Total workout duration
- `formattedDuration` - "Xm Ys" format
- `totalSets` - Total sets across all exercises
- `totalReps` - Total reps across all exercises
- `totalVolume` - Total volume (weight × reps) across all exercises
- `exerciseNames` - List of unique exercise names
- `exerciseCount` - Number of exercises

**Methods:**
- `addExercise(Exercise)` - Add an exercise to this workout
- `complete()` - Mark workout as complete

**Example:**
```dart
Workout(
  startTime: DateTime.now(),
  exercises: [
    Exercise(name: 'bench_press', sets: [...]),
    Exercise(name: 'squat', sets: [...]),
  ],
  isCompleted: true,
)
```

## WorkoutService API

### Initialization
```dart
await WorkoutService.init();
```

### Creating and Managing Workouts
```dart
// Create a new workout
final workout = await WorkoutService.createWorkout(notes: 'Chest day');

// Get current active workout
final activeWorkout = WorkoutService.getActiveWorkout();

// Add exercise to workout
await WorkoutService.addExerciseToWorkout(
  workout,
  'bench_press',
  notes: 'Heavy day',
);

// Add set to exercise
await WorkoutService.addSetToExercise(
  workout,
  'bench_press',
  reps: 8,
  weight: 225.0,
  restTimeSeconds: 90,
);

// Complete workout
await WorkoutService.completeWorkout(workout);
```

### Querying Workouts
```dart
// Get all workouts
final allWorkouts = WorkoutService.getAllWorkouts();

// Get completed workouts (sorted by most recent)
final completed = WorkoutService.getCompletedWorkouts();

// Get workouts in date range
final thisWeek = WorkoutService.getWorkoutsInRange(
  DateTime.now().subtract(Duration(days: 7)),
  DateTime.now(),
);

// Get workout by ID
final workout = WorkoutService.getWorkoutById('12345');
```

### Statistics
```dart
// Total workout count
int count = WorkoutService.getTotalWorkoutCount();

// Total sets across all workouts
int sets = WorkoutService.getTotalSets();

// Total reps across all workouts
int reps = WorkoutService.getTotalReps();

// Total volume (weight × reps)
double volume = WorkoutService.getTotalVolume();

// Current workout streak (consecutive days)
int streak = WorkoutService.getWorkoutStreak();

// Most frequent exercise
String? exercise = WorkoutService.getMostFrequentExercise();
```

### Maintenance
```dart
// Delete a workout
await WorkoutService.deleteWorkout(workout);

// Clear all workouts (for testing)
await WorkoutService.clearAllWorkouts();

// Close service
await WorkoutService.close();
```

## Integration with Voice Commands

The workout service is designed to work seamlessly with voice commands. Example flow:

1. **Start Workout**: `createWorkout()`
2. **Voice Command**: "Log 3 sets of 8 bench presses at 225 pounds"
3. **Parse & Save**:
```dart
for (int i = 0; i < 3; i++) {
  await WorkoutService.addSetToExercise(
    workout,
    'bench_press',
    reps: 8,
    weight: 225.0,
  );
}
```
4. **Complete**: `completeWorkout(workout)`

## Data Persistence

All workout data is automatically persisted to local storage via Hive:
- Survives app restarts
- No network required
- Fast read/write operations
- Automatic type safety with generated adapters

## Home Screen Integration

The `HomeScreen` now displays real-time stats:
- Total workouts completed
- Total sets logged
- Current workout streak (consecutive days)

These stats update automatically as workouts are logged and completed.

