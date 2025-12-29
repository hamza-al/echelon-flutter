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
    // Group sets by exercise
    final groupedExercises = <String, List<Map<String, dynamic>>>{};
    for (final set in loggedSets) {
      final exercise = set['exercise'] as String;
      if (!groupedExercises.containsKey(exercise)) {
        groupedExercises[exercise] = [];
      }
      groupedExercises[exercise]!.add(set);
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - same style as exercise name
          Text(
            'Logged',
            style: AppStyles.mainText().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Exercise cards
          ...groupedExercises.entries.map((entry) {
            final exerciseName = _formatExerciseName(entry.key);
            final sets = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise name
                    Text(
                      exerciseName.toUpperCase(),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Summary: total sets
                    Row(
                      children: [
                        Text(
                          '${sets.length}',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SETS',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              _getSetSummary(sets[0]),
                              style: AppStyles.mainText().copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.4),
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
          }).toList(),
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
      // Duration-based exercise
      final minutes = durationSeconds ~/ 60;
      final seconds = durationSeconds % 60;
      if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      }
      return '${seconds}s';
    } else {
      // Weight-based exercise
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

