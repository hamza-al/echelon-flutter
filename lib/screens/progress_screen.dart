import 'package:flutter/material.dart';
import '../styles.dart';
import '../services/workout_service.dart';
import '../services/user_service.dart';
import '../services/class_service.dart';
import '../services/split_service.dart';
import '../models/workout.dart';
import '../models/class_entry.dart';
import 'workout_detail_screen.dart';
import 'weekly_calendar_screen.dart';
import 'all_exercises_progress_screen.dart';
import 'log_class_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _totalSessions = 0;
  int _currentStreak = 0;
  List<Workout> _recentWorkouts = [];

  int _sessionsThisWeek = 0;
  int _prsThisWeek = 0;
  double _volumeThisWeek = 0;

  double _avgWorkoutsPerWeek = 0;
  String _mostTrainedExercise = '';
  double _avgRestDays = 0;

  Map<String, double> _exercisePRs = {};
  Map<String, int> _exerciseMaxReps = {};
  Map<String, DateTime> _exercisePRDates = {};
  Map<String, List<double>> _exerciseVolumeHistory = {};
  Map<String, List<DateTime>> _exerciseWorkoutDates = {};
  Map<String, List<double>> _exerciseMaxWeightHistory = {};

  List<ClassEntry> _recentClasses = [];
  Set<DateTime> _trainingDatesThisWeek = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final workouts = WorkoutService.getCompletedWorkouts();
    final allClasses = ClassService.getAllClasses();

    if (workouts.isEmpty && allClasses.isEmpty) {
      setState(() {
        _recentWorkouts = [];
        _recentClasses = [];
      });
      return;
    }

    final workoutDatesSet = workouts
        .map((w) =>
            DateTime(w.startTime.year, w.startTime.month, w.startTime.day))
        .toSet();
    final classDatesSet = ClassService.getClassDates();
    final allTrainingDates = {...workoutDatesSet, ...classDatesSet}.toList()
      ..sort();

    int currentStreak = 0;
    if (allTrainingDates.isNotEmpty) {
      final now = DateTime.now();
      var checkDate = DateTime(now.year, now.month, now.day);
      if (allTrainingDates.contains(checkDate)) {
        currentStreak = 1;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        checkDate = checkDate.subtract(const Duration(days: 1));
        if (allTrainingDates.contains(checkDate)) {
          currentStreak = 1;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
      while (allTrainingDates.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    final user = UserService.getCurrentUser();
    user.updateLongestStreak(currentStreak);
    user.save();

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final workoutsThisWeekList = workouts
        .where((w) =>
            w.startTime.isAfter(startOfWeek) ||
            w.startTime.isAtSameMomentAs(startOfWeek))
        .toList();
    final classesThisWeek = allClasses
        .where((c) =>
            c.timestamp.isAfter(startOfWeek) ||
            c.timestamp.isAtSameMomentAs(startOfWeek))
        .length;

    double volumeThisWeek = 0;
    for (final w in workoutsThisWeekList) {
      volumeThisWeek += w.totalVolume;
    }

    // Build training dates set for week strip
    final trainingDatesThisWeek = <DateTime>{};
    for (final w in workouts) {
      final d =
          DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      if (d.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        trainingDatesThisWeek.add(d);
      }
    }
    for (final c in allClasses) {
      final d =
          DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
      if (d.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        trainingDatesThisWeek.add(d);
      }
    }

    double avgPerWeek = 0;
    if (workouts.isNotEmpty) {
      final firstWorkoutDate = workouts.last.startTime;
      final weeksSinceStart = now.difference(firstWorkoutDate).inDays / 7;
      avgPerWeek = weeksSinceStart > 0
          ? workouts.length / weeksSinceStart
          : workouts.length.toDouble();
    }

    final exerciseCount = <String, int>{};
    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        exerciseCount[exercise.name] =
            (exerciseCount[exercise.name] ?? 0) + 1;
      }
    }
    String mostTrained = '';
    if (exerciseCount.isNotEmpty) {
      mostTrained = exerciseCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    double avgRest = 0;
    if (workouts.length > 1) {
      final wDates = workouts
          .map((w) => DateTime(
              w.startTime.year, w.startTime.month, w.startTime.day))
          .toSet()
          .toList()
        ..sort();
      int totalGaps = 0;
      for (int i = 1; i < wDates.length; i++) {
        totalGaps += wDates[i].difference(wDates[i - 1]).inDays - 1;
      }
      avgRest = wDates.length > 1 ? totalGaps / (wDates.length - 1) : 0;
    }

    final prs = <String, double>{};
    final prDates = <String, DateTime>{};
    final maxRepsPerExercise = <String, int>{};
    final volumeHistory = <String, List<double>>{};
    final workoutDates = <String, List<DateTime>>{};
    final maxWeightHistory = <String, List<double>>{};

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!volumeHistory.containsKey(exercise.name)) {
          volumeHistory[exercise.name] = [];
          workoutDates[exercise.name] = [];
          maxWeightHistory[exercise.name] = [];
        }
        double exerciseVolume = 0;
        double maxWeightThisWorkout = 0;

        for (var set in exercise.sets) {
          if (set.reps > (maxRepsPerExercise[exercise.name] ?? 0)) {
            maxRepsPerExercise[exercise.name] = set.reps;
          }
          if (set.weight != null && set.weight! > 0) {
            if (set.weight! > (prs[exercise.name] ?? 0)) {
              prs[exercise.name] = set.weight!;
              prDates[exercise.name] = workout.startTime;
            }
            if (set.weight! > maxWeightThisWorkout) {
              maxWeightThisWorkout = set.weight!;
            }
            exerciseVolume += set.weight! * set.reps;
          }
        }

        volumeHistory[exercise.name]!.add(exerciseVolume);
        workoutDates[exercise.name]!.add(workout.startTime);
        if (maxWeightThisWorkout > 0) {
          maxWeightHistory[exercise.name]!.add(maxWeightThisWorkout);
        }
      }
    }

    int prsThisWeek = 0;
    for (var prDate in prDates.values) {
      if (prDate.isAfter(startOfWeek)) prsThisWeek++;
    }

    setState(() {
      _totalSessions =
          WorkoutService.getTotalWorkoutCount() + ClassService.getTotalClassCount();
      _currentStreak = currentStreak;
      _recentWorkouts = workouts.take(5).toList();

      _sessionsThisWeek = workoutsThisWeekList.length + classesThisWeek;
      _prsThisWeek = prsThisWeek;
      _volumeThisWeek = volumeThisWeek;
      _trainingDatesThisWeek = trainingDatesThisWeek;

      _avgWorkoutsPerWeek = avgPerWeek;
      _mostTrainedExercise = mostTrained;
      _avgRestDays = avgRest;

      _exercisePRs = prs;
      _exercisePRDates = prDates;
      _exerciseMaxReps = maxRepsPerExercise;
      _exerciseVolumeHistory = volumeHistory;
      _exerciseWorkoutDates = workoutDates;
      _exerciseMaxWeightHistory = maxWeightHistory;

      _recentClasses = allClasses.take(5).toList();
    });
  }

  String _formatVolume(double vol) {
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}k';
    return vol.toStringAsFixed(0);
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
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _recentWorkouts.isEmpty && _recentClasses.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: isEmpty ? _buildEmptyState() : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No activity yet',
              style: AppStyles.mainHeader().copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first workout to start tracking progress.',
              textAlign: TextAlign.center,
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        // 1. Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Progress',
              style: AppStyles.mainHeader().copyWith(fontSize: 30),
            ),
            if (_currentStreak > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.overlay.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppColors.overlay.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      '$_currentStreak',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.overlay.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$_totalSessions sessions',
          style: AppStyles.mainText().copyWith(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 28),

        // 2. Week Activity Strip
        _buildWeekStrip(),

        const SizedBox(height: 20),

        // 3. Stats Row
        _buildStatsRow(),

        const SizedBox(height: 28),

        // 4. Top Lifts
        if (_exercisePRs.isNotEmpty) ...[
          _buildTopLifts(),
          const SizedBox(height: 28),
        ],

        // 5. Training Insights
        if (_totalSessions >= 3) ...[
          _buildInsights(),
          const SizedBox(height: 28),
        ],

        // 6. Recent Activity
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todaysWorkout = SplitService.getTodaysWorkout();

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => const WeeklyCalendarScreen()))
            .then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.overlay.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Today — $todaysWorkout',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.overlay.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.overlay.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final day = monday.add(Duration(days: i));
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                final isTrained = _trainingDatesThisWeek.contains(day);
                final isFuture = day.isAfter(now);

                return Column(
                  children: [
                    Text(
                      dayLabels[i],
                      style: AppStyles.mainText().copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? AppColors.overlay.withValues(alpha: 0.8)
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTrained
                            ? AppColors.overlay.withValues(alpha: 0.12)
                            : Colors.transparent,
                        border: isToday && !isTrained
                            ? Border.all(
                                color: AppColors.overlay.withValues(alpha: 0.20),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isTrained
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.overlay.withValues(alpha: 0.8),
                                ),
                              )
                            : isFuture
                                ? null
                                : Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          AppColors.overlay.withValues(alpha: 0.08),
                                    ),
                                  ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCell(
            '$_sessionsThisWeek',
            'Sessions',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCell(
            '${_formatVolume(_volumeThisWeek)} lbs',
            'Volume',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCell(
            '$_prsThisWeek',
            'PRs',
          ),
        ),
      ],
    );
  }

  Widget _statCell(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.03),
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
            style: AppStyles.mainText().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
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

  Widget _buildTopLifts() {
    final exerciseFreq = <String, int>{};
    for (var e in _exerciseWorkoutDates.entries) {
      exerciseFreq[e.key] = e.value.length;
    }
    final sorted = exerciseFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AllExercisesProgressScreen(
                exercisePRs: _exercisePRs,
                exerciseMaxReps: _exerciseMaxReps,
                exercisePRDates: _exercisePRDates,
                exerciseVolumeHistory: _exerciseVolumeHistory,
                exerciseWorkoutDates: _exerciseWorkoutDates,
                exerciseMaxWeightHistory: _exerciseMaxWeightHistory,
              ),
            ));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Lifts',
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sorted.length > 3)
                Text(
                  'See all',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...top.map((name) => _buildLiftRow(name)),
      ],
    );
  }

  Widget _buildLiftRow(String exerciseName) {
    final pr = _exercisePRs[exerciseName];
    final sessions = (_exerciseWorkoutDates[exerciseName] ?? []).length;
    final weightData =
        (_exerciseMaxWeightHistory[exerciseName] ?? []).reversed.toList();
    final volumeData =
        (_exerciseVolumeHistory[exerciseName] ?? []).reversed.toList();

    bool hasUpwardTrend = false;
    double? weightIncrease;
    if (weightData.length >= 2) {
      final first = weightData.first;
      final last = weightData.last;
      if (first > 0) weightIncrease = ((last - first) / first) * 100;
    }
    if (volumeData.length >= 2) {
      final recent = volumeData.length >= 3
          ? (volumeData[volumeData.length - 1] +
                  volumeData[volumeData.length - 2] +
                  volumeData[volumeData.length - 3]) /
              3
          : (volumeData[volumeData.length - 1] +
                  volumeData[volumeData.length - 2]) /
              2;
      final older = volumeData.length >= 4
          ? (volumeData[0] + volumeData[1]) / 2
          : volumeData[0];
      hasUpwardTrend = recent > older;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatExerciseName(exerciseName),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (pr != null) '${pr.toInt()} lbs',
                        '$sessions sessions',
                      ].join(' · '),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (weightIncrease != null && weightIncrease > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.overlay.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${weightIncrease.toStringAsFixed(0)}%',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.overlay.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                hasUpwardTrend ? Icons.trending_up : Icons.trending_flat,
                color: hasUpwardTrend
                    ? AppColors.overlay.withValues(alpha: 0.4)
                    : AppColors.overlay.withValues(alpha: 0.15),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: CustomPaint(
              painter: _MiniChartPainter(
                data: weightData.isNotEmpty ? weightData : volumeData,
                color: AppColors.overlay.withValues(alpha: 0.5),
              ),
              size: const Size(double.infinity, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final items = <String>[];
    if (_avgWorkoutsPerWeek > 0) {
      items.add('${_avgWorkoutsPerWeek.toStringAsFixed(1)} avg/week');
    }
    if (_avgRestDays > 0) {
      items.add('${_avgRestDays.toStringAsFixed(1)}d avg rest');
    }
    if (_mostTrainedExercise.isNotEmpty) {
      items.add('Top: ${_formatExerciseName(_mostTrainedExercise)}');
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: AppStyles.mainText().copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          items.join(' · '),
          style: AppStyles.mainText().copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    // Merge workouts and classes into a single sorted list
    final activities = <_ActivityItem>[];

    final grouped = <DateTime, List<Workout>>{};
    for (var w in _recentWorkouts) {
      final d =
          DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      (grouped[d] ??= []).add(w);
    }
    for (var entry in grouped.entries) {
      activities.add(_ActivityItem(
        date: entry.key,
        workouts: entry.value,
      ));
    }

    for (var c in _recentClasses) {
      activities.add(_ActivityItem(
        date: DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day),
        classEntry: c,
      ));
    }

    activities.sort((a, b) => b.date.compareTo(a.date));
    final toShow = activities.take(6).toList();

    if (toShow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent',
          style: AppStyles.mainText().copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        ...toShow.map((a) {
          if (a.classEntry != null) return _buildClassRow(a.classEntry!);
          return _buildWorkoutRow(a.date, a.workouts!);
        }),
      ],
    );
  }

  Widget _buildWorkoutRow(DateTime date, List<Workout> workouts) {
    final allExercises =
        workouts.expand((w) => w.exerciseNames).toSet().toList();
    final totalSets = workouts.fold(0, (sum, w) => sum + w.totalSets);
    final duration = workouts.first.formattedDuration;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workout: workouts.first),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.overlay.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(date),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalSets sets · $duration · ${allExercises.join(' · ')}',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.overlay.withValues(alpha: 0.15),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassRow(ClassEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (_) => LogClassScreen(existingEntry: entry),
            ))
            .then((r) {
          if (r == true) _loadStats();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.overlay.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.className,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      _formatDate(entry.timestamp),
                      if (entry.durationMinutes != null)
                        entry.durationFormatted,
                      if (entry.intensity != null)
                        const ['', 'Light', 'Moderate', 'Hard', 'Intense', 'Max'][entry.intensity!],
                      if (entry.caloriesBurned != null)
                        '~${entry.caloriesBurned} cal',
                    ].join(' · '),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.overlay.withValues(alpha: 0.15),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem {
  final DateTime date;
  final List<Workout>? workouts;
  final ClassEntry? classEntry;

  _ActivityItem({required this.date, this.workouts, this.classEntry});
}

class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartData = data.length == 1 ? [0.0, data.first] : data;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final maxVal = chartData.reduce((a, b) => a > b ? a : b);
    final minVal = chartData.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    if (range == 0) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      return;
    }

    final points = <Offset>[];
    final stepX = size.width / (chartData.length - 1);
    for (int i = 0; i < chartData.length; i++) {
      final x = i * stepX;
      final norm = (chartData[i] - minVal) / range;
      final y = size.height - (norm * size.height * 0.85) - size.height * 0.05;
      points.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      areaPath.lineTo(points[i].dx, points[i].dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();
    canvas.drawPath(areaPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) =>
      old.data != data || old.color != color;
}
