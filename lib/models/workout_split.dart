import 'package:hive_ce/hive.dart';

part 'workout_split.g.dart';

@HiveType(typeId: 8)
class WorkoutSplit extends HiveObject {
  @HiveField(0)
  String splitType;

  @HiveField(1)
  List<String> dayNames;

  WorkoutSplit({
    required this.splitType,
    required this.dayNames,
  });

  // Get the workout for a specific day of the week (0 = Monday, 6 = Sunday)
  String getDayWorkout(int dayOfWeek) {
    if (dayOfWeek < 0 || dayOfWeek >= dayNames.length) {
      return 'Rest';
    }
    return dayNames[dayOfWeek];
  }

  // Static split configurations
  static WorkoutSplit pushPullLegs() {
    return WorkoutSplit(
      splitType: 'Push/Pull/Legs',
      dayNames: ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs', 'Rest'],
    );
  }

  static WorkoutSplit upperLower() {
    return WorkoutSplit(
      splitType: 'Upper/Lower',
      dayNames: ['Upper', 'Lower', 'Rest', 'Upper', 'Lower', 'Rest', 'Rest'],
    );
  }

  static WorkoutSplit broSplit() {
    return WorkoutSplit(
      splitType: 'Bro Split',
      dayNames: ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Rest', 'Rest'],
    );
  }

  static WorkoutSplit fullBody() {
    return WorkoutSplit(
      splitType: 'Full Body',
      dayNames: ['Full Body', 'Rest', 'Full Body', 'Rest', 'Full Body', 'Rest', 'Rest'],
    );
  }

  static WorkoutSplit arnoldSplit() {
    return WorkoutSplit(
      splitType: 'Arnold Split',
      dayNames: ['Chest/Back', 'Shoulders/Arms', 'Legs', 'Chest/Back', 'Shoulders/Arms', 'Legs', 'Rest'],
    );
  }

  static WorkoutSplit powerbuilding() {
    return WorkoutSplit(
      splitType: 'Powerbuilding',
      dayNames: ['Power Upper', 'Power Lower', 'Rest', 'Hypertrophy Upper', 'Hypertrophy Lower', 'Rest', 'Rest'],
    );
  }

  static WorkoutSplit custom({List<String>? dayNames}) {
    return WorkoutSplit(
      splitType: 'Custom',
      dayNames: dayNames ?? ['Rest', 'Rest', 'Rest', 'Rest', 'Rest', 'Rest', 'Rest'],
    );
  }

  // Get all available splits
  static List<WorkoutSplit> getAllSplits() {
    return [
      pushPullLegs(),
      upperLower(),
      broSplit(),
      fullBody(),
      arnoldSplit(),
      powerbuilding(),
      custom(),
    ];
  }
}
