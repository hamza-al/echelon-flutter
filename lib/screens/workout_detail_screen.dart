import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(workout.startTime),
                          style: AppStyles.mainHeader().copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          workout.formattedDuration,
                          style: AppStyles.questionSubtext().copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      workout.exercises.length.toString(),
                      'Exercises',
                      Icons.fitness_center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      workout.totalSets.toString(),
                      'Sets',
                      Icons.repeat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      workout.totalReps.toString(),
                      'Reps',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Exercises List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: workout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = workout.exercises[index];
                  return _buildExerciseCard(exercise);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppStyles.secondaryHeader().copyWith(
              fontSize: 24,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppStyles.mainText().copyWith(
              fontSize: 11,
              color: AppColors.accent.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Row(
            children: [
              Text(
                _formatExerciseName(exercise.name),
                style: AppStyles.mainText().copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (exercise.isDurationBased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CARDIO',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sets list
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            final isLast = setIndex == exercise.sets.length - 1;
            
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Row(
                children: [
                  // Set number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${set.setNumber}',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Set details (duration-based or weight-based)
                  Expanded(
                    child: exercise.isDurationBased
                        ? _buildDurationSetDetails(set)
                        : _buildWeightSetDetails(set),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeightSetDetails(set) {
    return Row(
      children: [
        Text(
          '${set.reps} reps',
          style: AppStyles.mainText().copyWith(
            fontSize: 14,
            color: AppColors.accent.withOpacity(0.9),
          ),
        ),
        if (set.weight != null && set.weight! > 0) ...[
          Text(
            ' @ ',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              color: AppColors.accent.withOpacity(0.5),
            ),
          ),
          Text(
            '${set.weight!.toInt()} lbs',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
        if (set.isBodyweight)
          Text(
            ' (bodyweight)',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              color: AppColors.accent.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildDurationSetDetails(set) {
    return Text(
      set.durationDisplay,
      style: AppStyles.mainText().copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
    );
  }

  String _formatExerciseName(String name) {
    // Convert snake_case to Title Case
    return name
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(workoutDate).inDays;

    if (difference == 0) {
      return 'Today\'s Workout';
    } else if (difference == 1) {
      return 'Yesterday\'s Workout';
    } else if (difference < 7) {
      return 'Workout - $difference days ago';
    } else {
      return 'Workout - ${date.month}/${date.day}/${date.year}';
    }
  }
}

