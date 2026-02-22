import 'package:flutter/material.dart';
import '../styles.dart';

class AllExercisesProgressScreen extends StatelessWidget {
  final Map<String, double> exercisePRs;
  final Map<String, int> exerciseMaxReps;
  final Map<String, DateTime> exercisePRDates;
  final Map<String, List<double>> exerciseVolumeHistory;
  final Map<String, List<DateTime>> exerciseWorkoutDates;
  final Map<String, List<double>> exerciseMaxWeightHistory;

  const AllExercisesProgressScreen({
    super.key,
    required this.exercisePRs,
    required this.exerciseMaxReps,
    required this.exercisePRDates,
    required this.exerciseVolumeHistory,
    required this.exerciseWorkoutDates,
    required this.exerciseMaxWeightHistory,
  });

  @override
  Widget build(BuildContext context) {
    // Get all exercises sorted by frequency
    final exerciseFrequency = <String, int>{};
    for (var dates in exerciseWorkoutDates.entries) {
      exerciseFrequency[dates.key] = dates.value.length;
    }
    
    final sortedExercises = exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.accent,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Exercises',
                          style: AppStyles.mainHeader().copyWith(
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sortedExercises.length} exercises tracked',
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
            
            // Exercise list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sortedExercises.length,
                itemBuilder: (context, index) {
                  final exerciseName = sortedExercises[index].key;
                  final volumeData = (exerciseVolumeHistory[exerciseName] ?? []).reversed.toList();
                  final weightData = (exerciseMaxWeightHistory[exerciseName] ?? []).reversed.toList();
                  final dates = (exerciseWorkoutDates[exerciseName] ?? []).reversed.toList();
                  
                  // Calculate trend
                  bool hasUpwardTrend = false;
                  if (volumeData.length >= 2) {
                    final recentAvg = volumeData.length >= 3
                        ? (volumeData[volumeData.length - 1] + volumeData[volumeData.length - 2] + volumeData[volumeData.length - 3]) / 3
                        : (volumeData[volumeData.length - 1] + volumeData[volumeData.length - 2]) / 2;
                    final olderAvg = volumeData.length >= 4
                        ? (volumeData[0] + volumeData[1]) / 2
                        : volumeData[0];
                    hasUpwardTrend = recentAvg > olderAvg;
                  }
                  
                  // Calculate percentage increase in max weight
                  double? weightIncrease;
                  if (weightData.length >= 2) {
                    final firstWeight = weightData.first;
                    final lastWeight = weightData.last;
                    if (firstWeight > 0) {
                      weightIncrease = ((lastWeight - firstWeight) / firstWeight) * 100;
                    }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        _showExerciseDetailModal(
                          context,
                          exerciseName,
                          dates,
                          volumeData,
                          weightData,
                        );
                      },
                      child: _buildExerciseProgressCard(
                        exerciseName: exerciseName,
                        timesPerformed: dates.length,
                        hasUpwardTrend: hasUpwardTrend,
                        weightIncrease: weightIncrease,
                        volumeData: volumeData,
                        weightData: weightData,
                        pr: exercisePRs[exerciseName],
                        maxReps: exerciseMaxReps[exerciseName],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseProgressCard({
    required String exerciseName,
    required int timesPerformed,
    required bool hasUpwardTrend,
    required double? weightIncrease,
    required List<double> volumeData,
    required List<double> weightData,
    double? pr,
    int? maxReps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatExerciseName(exerciseName),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$timesPerformed ${timesPerformed == 1 ? 'session' : 'sessions'}',
                      style: AppStyles.questionSubtext().copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (weightIncrease != null && weightIncrease > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${weightIncrease.toStringAsFixed(0)}%',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    hasUpwardTrend ? Icons.trending_up : Icons.trending_flat,
                    color: hasUpwardTrend ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          
          // PR info if available
          if (pr != null && maxReps != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PR: ${pr.toInt()} × $maxReps',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Chart
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: _MiniChartPainter(
                data: weightData.isNotEmpty ? weightData : volumeData,
                color: AppColors.primaryLight,
              ),
              size: const Size(double.infinity, 60),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExerciseName(String name) {
    return name
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showExerciseDetailModal(
    BuildContext context,
    String exerciseName,
    List<DateTime> dates,
    List<double> volumeData,
    List<double> weightData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatExerciseName(exerciseName),
                            style: AppStyles.mainHeader().copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dates.length} workout${dates.length == 1 ? '' : 's'}',
                            style: AppStyles.questionSubtext().copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.accent),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Workout history list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[dates.length - 1 - index]; // Reverse to show newest first
                    final volume = volumeData.isNotEmpty && (dates.length - 1 - index) < volumeData.length
                        ? volumeData[dates.length - 1 - index]
                        : null;
                    final maxWeight = weightData.isNotEmpty && (dates.length - 1 - index) < weightData.length
                        ? weightData[dates.length - 1 - index]
                        : null;
                    
                    return _buildWorkoutDataPoint(
                      date: date,
                      volume: volume,
                      maxWeight: maxWeight,
                      index: index + 1, // Show newest as higher numbers
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDataPoint({
    required DateTime date,
    required double? volume,
    required double? maxWeight,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session #$index',
                style: AppStyles.mainText().copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(date),
                style: AppStyles.questionSubtext().copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (maxWeight != null && maxWeight > 0) ...[
                Expanded(
                  child: _buildStatChip(
                    label: 'Max Weight',
                    value: '${maxWeight.toStringAsFixed(0)} lbs',
                    icon: Icons.fitness_center,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (volume != null && volume > 0)
                Expanded(
                  child: _buildStatChip(
                    label: 'Volume',
                    value: '${volume.toStringAsFixed(0)} lbs',
                    icon: Icons.bar_chart,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppStyles.mainText().copyWith(
                  fontSize: 11,
                  color: AppColors.accent.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppStyles.mainText().copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(workoutDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

// Custom painter for mini progress charts
class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // If only one data point, prepend a zero so we draw a line showing progress
    final chartData = data.length == 1 ? [0.0, data.first] : data;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Find min and max for scaling
    final maxValue = chartData.reduce((a, b) => a > b ? a : b);
    final minValue = chartData.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) {
      // If all values are the same, draw a flat line
      final y = size.height / 2;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);
      canvas.drawPath(path, linePaint);
      return;
    }

    // Calculate points
    final points = <Offset>[];
    final stepX = size.width / (chartData.length - 1);

    for (int i = 0; i < chartData.length; i++) {
      final x = i * stepX;
      final normalizedValue = (chartData[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    // Draw filled area under the line
    final areaPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      areaPath.lineTo(points[i].dx, points[i].dy);
    }

    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();
    canvas.drawPath(areaPath, paint);

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots at each data point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MiniChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
