import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(workout.startTime),
                          style: AppStyles.mainHeader().copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          workout.formattedDuration,
                          style: AppStyles.mainText().copyWith(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard(
                      workout.exercises.length.toString(),
                      'Exercises',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      workout.totalSets.toString(),
                      'Sets',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      workout.totalReps.toString(),
                      'Reps',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: workout.exercises.length,
                itemBuilder: (context, index) {
                  return _buildExerciseCard(workout.exercises[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppStyles.secondaryHeader().copyWith(
              fontSize: 22,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppStyles.mainText().copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatExerciseName(exercise.name),
                  style: AppStyles.mainText().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (exercise.isDurationBased)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.overlay.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CARDIO',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.overlay.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            final isLast = setIndex == exercise.sets.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.overlay.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${set.setNumber}',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.overlay.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: exercise.isDurationBased
                        ? Text(
                            set.durationDisplay,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : _buildWeightSetRow(set),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeightSetRow(dynamic set) {
    return Row(
      children: [
        Text(
          '${set.reps} reps',
          style: AppStyles.mainText().copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        if (set.weight != null && set.weight! > 0) ...[
          Text(
            ' @ ',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            '${set.weight!.toInt()} lbs',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (set.isBodyweight)
          Text(
            ' (bodyweight)',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  String _formatExerciseName(String name) {
    return name
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today\'s Workout';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
