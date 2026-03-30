import 'package:flutter/material.dart';
import '../styles.dart';

class WorkoutResultsDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> loggedSets;

  const WorkoutResultsDisplay({
    super.key,
    required this.loggedSets,
  });

  @override
  Widget build(BuildContext context) {
    final groupedExercises = <String, List<Map<String, dynamic>>>{};
    for (final set in loggedSets) {
      final exercise = set['exercise'] as String;
      if (!groupedExercises.containsKey(exercise)) {
        groupedExercises[exercise] = [];
      }
      groupedExercises[exercise]!.add(set);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LOGGED',
            style: AppStyles.mainText().copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 14),
          ...groupedExercises.entries.map((entry) {
            final exerciseName = _formatExerciseName(entry.key);
            final sets = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName.toUpperCase(),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${sets.length}',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SETS',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            Text(
                              _getSetSummary(sets[0]),
                              style: AppStyles.mainText().copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatExerciseName(String exercise) {
    return exercise
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getSetSummary(Map<String, dynamic> set) {
    final durationSeconds = set['duration_seconds'] as int? ?? 0;

    if (durationSeconds > 0) {
      final minutes = durationSeconds ~/ 60;
      final seconds = durationSeconds % 60;
      if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      }
      return '${seconds}s';
    } else {
      final reps = set['reps'];
      final weight = set['weight'];
      if (weight != null && weight > 0) {
        return '$reps reps × $weight lbs';
      } else {
        return '$reps reps (bodyweight)';
      }
    }
  }
}
