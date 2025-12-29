# Workout Schema Migration - Duration-Based Exercises

## Overview
The workout schema has been updated to support both **weight-based** (traditional resistance training) and **duration-based** (cardio, time-based) exercises.

## Changes

### 1. ExerciseSet Model
**New Fields:**
- `durationSeconds` (int?) - Duration for cardio exercises

**Modified Fields:**
- `reps` - Now defaults to 0 (optional for duration-based exercises)
- `isBodyweight` - Now defaults to false

### 2. Exercise Model
**New Fields:**
- `exerciseType` (String) - Either 'weight' or 'duration'

**New Getters:**
- `isWeightBased` - Returns true if exerciseType is 'weight'
- `isDurationBased` - Returns true if exerciseType is 'duration'
- `totalDurationSeconds` - Total duration for duration-based exercises
- `formattedTotalDuration` - Human-readable duration string

**Modified Getters:**
- `totalVolume` - Now returns 0.0 for duration-based exercises
- `totalReps` - Now returns 0 for duration-based exercises

### 3. WorkoutService
**New Methods:**
- `addDurationSetToExercise()` - Add duration-based sets (cardio)

**Modified Methods:**
- `addExerciseToWorkout()` - Now accepts `exerciseType` parameter
- `addSetToExercise()` - Now accepts optional `exerciseType` parameter

## Backend API Expected Formats

### Weight-Based Exercise
```json
{
  "type": "log_set",
  "payload": {
    "exercise": "bench_press",
    "reps": 8,
    "weight": 225,
    "duration_seconds": 0
  }
}
```

### Duration-Based Exercise (cardio)
```json
{
  "type": "log_set",
  "payload": {
    "exercise": "running",
    "reps": 0,
    "weight": 0,
    "duration_seconds": 1800
  }
}
```

**Important:** All fields are always present. Set irrelevant fields to 0:
- For weight-based exercises: Set `duration_seconds` to 0
- For duration-based exercises: Set `reps` to 0 and `weight` to 0

The app determines exercise type by checking if `duration_seconds > 0`.

## Migration Notes

### Existing Data
- All existing workouts will continue to work as they default to weight-based exercises
- No manual migration of existing data is required

### New Workouts
- The backend should send `duration_seconds` instead of `reps`/`weight` for cardio exercises
- The app will automatically detect the exercise type based on the payload fields

### Display Changes
- Workout detail screen now shows "CARDIO" badge for duration-based exercises
- Sets are displayed differently:
  - Weight-based: "8 reps @ 225 lbs"
  - Duration-based: "30m 0s"

## Examples

### Logging a Running Session
```dart
await WorkoutService.addDurationSetToExercise(
  workout,
  'running',
  1800, // 30 minutes
);
```

### Logging a Plank Hold
```dart
await WorkoutService.addDurationSetToExercise(
  workout,
  'plank',
  60, // 60 seconds
);
```

### Logging a Traditional Weight Exercise
```dart
await WorkoutService.addSetToExercise(
  workout,
  'bench_press',
  8,
  225.0,
);
```

## Testing
To test the new functionality:
1. Start a workout session
2. Say "Log 30 minutes of running"
3. The backend should recognize this as a duration-based exercise
4. The app will save it with the appropriate schema
5. View the workout detail to see the cardio badge and duration display

