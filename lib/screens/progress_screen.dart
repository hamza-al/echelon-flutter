import 'package:flutter/material.dart';
import '../styles.dart';
import '../services/workout_service.dart';
import '../services/user_service.dart';
import '../services/split_service.dart';
// import '../services/auth_service.dart';
import '../models/workout.dart';
import 'workout_detail_screen.dart';
import 'weekly_calendar_screen.dart';
import 'all_exercises_progress_screen.dart';
// import 'package:provider/provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  // int _longestStreak = 0; // TODO: Will be used for Milestones later
  List<Workout> _recentWorkouts = [];
  
  // This week stats
  int _workoutsThisWeek = 0;
  int _prsThisWeek = 0;
  String _lastTrained = '';
  
  // Training insights
  double _avgWorkoutsPerWeek = 0;
  String _mostTrainedExercise = '';
  double _avgRestDays = 0;
  
  // Personal records with timestamps
  Map<String, double> _exercisePRs = {}; // exercise -> heaviest weight
  Map<String, int> _exerciseMaxReps = {}; // exercise -> most reps
  Map<String, DateTime> _exercisePRDates = {}; // exercise -> when PR was set
  Map<String, List<double>> _exerciseVolumeHistory = {}; // exercise -> [volumes over time]
  Map<String, List<DateTime>> _exerciseWorkoutDates = {}; // exercise -> [dates performed]
  Map<String, List<double>> _exerciseMaxWeightHistory = {}; // exercise -> [max weights over time]

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final workouts = WorkoutService.getCompletedWorkouts();
    
    if (workouts.isEmpty) {
      setState(() {
        _recentWorkouts = [];
      });
      return;
    }
    
    // Get current streak and update user's longest streak if needed
    final currentStreak = WorkoutService.getWorkoutStreak();
    final user = UserService.getCurrentUser();
    user.updateLongestStreak(currentStreak);
    user.save();
    
    // Calculate "This Week" stats
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final workoutsThisWeek = workouts.where((w) => 
      w.startTime.isAfter(startOfWeek) || 
      w.startTime.isAtSameMomentAs(startOfWeek)
    ).length;
    
    // Last trained
    String lastTrained = '';
    if (workouts.isNotEmpty) {
      final lastWorkout = workouts.first;
      final daysSince = now.difference(lastWorkout.startTime).inDays;
      if (daysSince == 0) {
        lastTrained = 'Today';
      } else if (daysSince == 1) {
        lastTrained = 'Yesterday';
      } else {
        lastTrained = '$daysSince days ago';
      }
    }
    
    // Calculate avg workouts per week
    double avgPerWeek = 0;
    if (workouts.isNotEmpty) {
      final firstWorkoutDate = workouts.last.startTime;
      final weeksSinceStart = now.difference(firstWorkoutDate).inDays / 7;
      avgPerWeek = weeksSinceStart > 0 ? workouts.length / weeksSinceStart : workouts.length.toDouble();
    }
    
    // Most trained exercise
    final exerciseCount = <String, int>{};
    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        exerciseCount[exercise.name] = (exerciseCount[exercise.name] ?? 0) + 1;
      }
    }
    String mostTrained = '';
    if (exerciseCount.isNotEmpty) {
      mostTrained = exerciseCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    
    // Calculate avg rest days
    double avgRest = 0;
    if (workouts.length > 1) {
      final workoutDates = workouts.map((w) => DateTime(
        w.startTime.year,
        w.startTime.month,
        w.startTime.day,
      )).toSet().toList()..sort();
      
      int totalGaps = 0;
      for (int i = 1; i < workoutDates.length; i++) {
        totalGaps += workoutDates[i].difference(workoutDates[i - 1]).inDays - 1;
      }
      avgRest = workoutDates.length > 1 ? totalGaps / (workoutDates.length - 1) : 0;
    }
    
    // Calculate PRs with timestamps
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
    
    // Count PRs this week
    int prsThisWeek = 0;
    for (var prDate in prDates.values) {
      if (prDate.isAfter(startOfWeek)) {
        prsThisWeek++;
      }
    }
    
    setState(() {
      _totalWorkouts = WorkoutService.getTotalWorkoutCount();
      _currentStreak = currentStreak;
      // _longestStreak = user.longestStreak; // TODO: Will be used for Milestones later
      _recentWorkouts = workouts.take(5).toList();
      
      _workoutsThisWeek = workoutsThisWeek;
      _prsThisWeek = prsThisWeek;
      _lastTrained = lastTrained;
      
      _avgWorkoutsPerWeek = avgPerWeek;
      _mostTrainedExercise = mostTrained;
      _avgRestDays = avgRest;
      
      _exercisePRs = prs;
      _exercisePRDates = prDates;
      _exerciseMaxReps = maxRepsPerExercise;
      _exerciseVolumeHistory = volumeHistory;
      _exerciseWorkoutDates = workoutDates;
      _exerciseMaxWeightHistory = maxWeightHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _recentWorkouts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workouts yet',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 18,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your first workout to see progress',
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Header
                  Text(
                    'Workout Progress',
                    style: AppStyles.mainHeader().copyWith(
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$_totalWorkouts workouts',
                        style: AppStyles.questionSubtext(),
                      ),
                      if (_currentStreak > 0) ...[
                        Text(
                          ' • ',
                          style: AppStyles.questionSubtext(),
                        ),
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_currentStreak day streak',
                          style: AppStyles.questionSubtext(),
                        ),
                      ],
                      const Spacer(),
                      // Re-auth button for testing
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.refresh,
                      //     color: AppColors.accent.withOpacity(0.5),
                      //     size: 20,
                      //   ),
                      //   onPressed: () async {
                      //     final authService = Provider.of<AuthService>(context, listen: false);
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('Re-authenticating...')),
                      //     );
                      //     final success = await authService.register();
                      //     if (mounted) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //           content: Text(success ? '✅ Re-authenticated' : '❌ Failed'),
                      //         ),
                      //       );
                      //     }
                      //   },
                      //   tooltip: 'Re-authenticate',
                      // ),
                    ],
                  ),

                  // Debug: Clear workouts button
                  // if (_recentWorkouts.isNotEmpty)
                  //   Align(
                  //     alignment: Alignment.centerLeft,
                  //     child: Padding(
                  //       padding: const EdgeInsets.only(top: 8),
                  //       child: TextButton.icon(
                  //         onPressed: () async {
                  //           final confirm = await showDialog<bool>(
                  //             context: context,
                  //             builder: (context) => AlertDialog(
                  //               backgroundColor: AppColors.background,
                  //               title: Text(
                  //                 'Clear All Workouts?',
                  //                 style: AppStyles.mainText().copyWith(
                  //                   fontSize: 18,
                  //                   fontWeight: FontWeight.w600,
                  //                 ),
                  //               ),
                  //               content: Text(
                  //                 'This will permanently delete all workout data.',
                  //                 style: AppStyles.mainText().copyWith(
                  //                   fontSize: 15,
                  //                 ),
                  //               ),
                  //               actions: [
                  //                 TextButton(
                  //                   onPressed: () => Navigator.of(context).pop(false),
                  //                   child: Text(
                  //                     'Cancel',
                  //                     style: AppStyles.mainText().copyWith(
                  //                       fontSize: 15,
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 TextButton(
                  //                   onPressed: () => Navigator.of(context).pop(true),
                  //                   child: Text(
                  //                     'Clear',
                  //                     style: AppStyles.mainText().copyWith(
                  //                       fontSize: 15,
                  //                       color: Colors.red,
                  //                       fontWeight: FontWeight.w600,
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           );

                  //           if (confirm == true) {
                  //             await WorkoutService.clearAllWorkouts();
                  //             _loadStats();
                  //           }
                  //         },
                  //         icon: const Icon(
                  //           Icons.delete_outline,
                  //           size: 14,
                  //           color: Colors.red,
                  //         ),
                  //         label: Text(
                  //           'Clear All',
                  //           style: AppStyles.mainText().copyWith(
                  //             fontSize: 11,
                  //             color: Colors.red.withOpacity(0.8),
                  //           ),
                  //         ),
                  //         style: TextButton.styleFrom(
                  //           padding: const EdgeInsets.symmetric(
                  //             horizontal: 8,
                  //             vertical: 4,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),

                  const SizedBox(height: 32),

                  // Today's Workout
                  _buildTodaysWorkoutCard(),

                  const SizedBox(height: 24),

                  // This Week
                  _buildThisWeekCard(),

                  const SizedBox(height: 24),

                  // Exercise Progress (moved to top)
                  if (_exercisePRs.isNotEmpty) ...[
                    _buildExerciseProgress(),
                    const SizedBox(height: 24),
                  ],

                  // Personal Records
                  if (_exercisePRs.isNotEmpty) ...[
                    _buildExercisePRs(),
                    const SizedBox(height: 24),
                  ],

                  // Milestones (gated)
                  // TODO: Commenting out for now - have a plan for this later
                  // _buildMilestonesCard(),
                  // const SizedBox(height: 24),

                  // Training Insights
                  _buildTrainingInsights(),

                  const SizedBox(height: 24),

                  // Recent Workouts
                  Text(
                    'Recent Workouts',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ..._buildGroupedWorkoutCards(),
                ],
              ),
      ),
    );
  }

  Widget _buildTodaysWorkoutCard() {
    final todaysWorkout = SplitService.getTodaysWorkout();
    final isRest = todaysWorkout == 'Rest';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WeeklyCalendarScreen(),
          ),
        ).then((_) {
          // Rebuild to reflect any split changes
          setState(() {});
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryLight.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left side - purple tab indicator
            Container(
              width: 3,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Workout',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      color: AppColors.accent.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todaysWorkout,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isRest 
                          ? AppColors.accent.withOpacity(0.5) 
                          : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryLight,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // Group workouts by day and return cards
  List<Widget> _buildGroupedWorkoutCards() {
    final groupedWorkouts = <DateTime, List<Workout>>{};
    
    // Group workouts by day
    for (var workout in _recentWorkouts) {
      final workoutDate = DateTime(
        workout.startTime.year,
        workout.startTime.month,
        workout.startTime.day,
      );
      
      if (!groupedWorkouts.containsKey(workoutDate)) {
        groupedWorkouts[workoutDate] = [];
      }
      groupedWorkouts[workoutDate]!.add(workout);
    }
    
    // Sort dates descending
    final sortedDates = groupedWorkouts.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    // Build cards for each date
    return sortedDates.map((date) {
      final workouts = groupedWorkouts[date]!;
      return _buildWorkoutCard(date, workouts);
    }).toList();
  }

  Widget _buildThisWeekCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
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
                'This Week',
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildWeekStatCard(
                  value: '$_workoutsThisWeek',
                  label: 'Workouts',
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeekStatCard(
                  value: '$_prsThisWeek',
                  label: 'PRs',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          
          if (_lastTrained.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.accent.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last trained: ',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      color: AppColors.accent.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    _lastTrained,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppStyles.secondaryHeader().copyWith(
              fontSize: 32,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppStyles.questionSubtext().copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Milestones card - commented out for now, have a plan for this later
  // Widget _buildMilestonesCard() {
  //   final showStats = _longestStreak >= 7; // Gate until meaningful
  //   
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: AppColors.accent.withOpacity(0.03),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: AppColors.accent.withOpacity(0.1),
  //         width: 1,
  //       ),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Milestones',
  //           style: AppStyles.mainText().copyWith(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         
  //         if (showStats)
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _buildMilestoneStat(
  //                   '${max(_longestStreak, WorkoutService.getWorkoutStreak())} days',
  //                   'Longest streak',
  //                   Icons.local_fire_department,
  //                 ),
  //               ),
  //             ],
  //           )
  //         else
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'First workouts logged',
  //                 style: AppStyles.mainText().copyWith(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(height: 6),
  //               Text(
  //                 'Keep going — milestones unlock as you train',
  //                 style: AppStyles.questionSubtext().copyWith(
  //                   fontSize: 13,
  //                 ),
  //               ),
  //             ],
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMilestoneStat(String value, String label, IconData icon) {
  //   return Row(
  //     children: [
  //       Icon(
  //         icon,
  //         color: Colors.orange,
  //         size: 20,
  //       ),
  //       const SizedBox(width: 8),
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             value,
  //             style: AppStyles.mainText().copyWith(
  //               fontSize: 18,
  //               fontWeight: FontWeight.w700,
  //             ),
  //           ),
  //           Text(
  //             label,
  //             style: AppStyles.questionSubtext().copyWith(
  //               fontSize: 12,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTrainingInsights() {
    // Only show if we have meaningful data
    if (_totalWorkouts < 3) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
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
                'Training Insights',
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.insights_rounded,
                color: Colors.blue,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_avgWorkoutsPerWeek > 0)
            _buildInsightCard(
              icon: Icons.calendar_today_rounded,
              iconColor: Colors.blue,
              value: '${_avgWorkoutsPerWeek.toStringAsFixed(1)}',
              label: 'workouts / week',
            ),
          
          if (_mostTrainedExercise.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightCard(
              icon: Icons.fitness_center_rounded,
              iconColor: AppColors.primary,
              value: _formatExerciseName(_mostTrainedExercise),
              label: 'Most trained',
            ),
          ],
          
          if (_avgRestDays > 0) ...[
            const SizedBox(height: 12),
            _buildInsightCard(
              icon: Icons.bedtime_rounded,
              iconColor: Colors.orange,
              value: '${_avgRestDays.toStringAsFixed(1)} days',
              label: 'Avg rest',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppStyles.questionSubtext().copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseProgress() {
    // Get top exercises by frequency
    final exerciseFrequency = <String, int>{};
    for (var dates in _exerciseWorkoutDates.entries) {
      exerciseFrequency[dates.key] = dates.value.length;
    }
    
    // Sort by frequency and take top 2 for preview
    final topExercises = exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final exercisesToShow = topExercises.take(2).map((e) => e.key).toList();
    
    if (exercisesToShow.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: exerciseFrequency.length > 2 ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AllExercisesProgressScreen(
                    exercisePRs: _exercisePRs,
                    exerciseMaxReps: _exerciseMaxReps,
                    exercisePRDates: _exercisePRDates,
                    exerciseVolumeHistory: _exerciseVolumeHistory,
                    exerciseWorkoutDates: _exerciseWorkoutDates,
                    exerciseMaxWeightHistory: _exerciseMaxWeightHistory,
                  ),
                ),
              );
            } : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Exercise Progress',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (exerciseFrequency.length > 2) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${exerciseFrequency.length})',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                    if (exerciseFrequency.length > 2) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          ...exercisesToShow.map((exerciseName) {
            final volumeData = (_exerciseVolumeHistory[exerciseName] ?? []).reversed.toList();
            final weightData = (_exerciseMaxWeightHistory[exerciseName] ?? []).reversed.toList();
            final dates = (_exerciseWorkoutDates[exerciseName] ?? []).reversed.toList();
            
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
              child: _buildExerciseProgressCard(
                exerciseName: exerciseName,
                timesPerformed: dates.length,
                hasUpwardTrend: hasUpwardTrend,
                weightIncrease: weightIncrease,
                volumeData: volumeData,
                weightData: weightData,
              ),
            );
          }).toList(),
        ],
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
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
                        fontSize: 15,
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
          const SizedBox(height: 12),
          
          // Mini chart
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: _MiniChartPainter(
                data: weightData.isNotEmpty ? weightData : volumeData,
                color: AppColors.primaryLight,
              ),
              size: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePRs() {
    // Sort by most recent PRs first
    final sortedPRs = _exercisePRs.entries.toList()
      ..sort((a, b) {
        final dateA = _exercisePRDates[a.key];
        final dateB = _exercisePRDates[b.key];
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
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
                'Personal Records',
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...sortedPRs.take(2).map((entry) {
            final maxReps = _exerciseMaxReps[entry.key] ?? 0;
            final prDate = _exercisePRDates[entry.key];
            final volumeHistory = _exerciseVolumeHistory[entry.key] ?? [];
            final hasGrowth = volumeHistory.length >= 2 && 
                            volumeHistory.last > volumeHistory[volumeHistory.length - 2];
            
            // Format PR time
            String prTime = '';
            if (prDate != null) {
              final now = DateTime.now();
              final daysSince = now.difference(prDate).inDays;
              if (daysSince == 0) {
                prTime = '(Today)';
              } else if (daysSince < 7) {
                prTime = '(This week)';
              } else if (daysSince < 30) {
                prTime = '(${(daysSince / 7).round()} weeks ago)';
              }
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatExerciseName(entry.key),
                          style: AppStyles.mainText().copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.value.toInt()} × $maxReps $prTime',
                          style: AppStyles.questionSubtext().copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasGrowth)
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                      size: 16,
                    ),
                ],
              ),
            );
          }).toList(),
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

  Widget _buildWorkoutCard(DateTime date, List<Workout> workouts) {
    // Combine all exercises from all workouts on this day
    final allExercises = workouts
        .expand((w) => w.exerciseNames)
        .toSet()
        .toList();
    
    // Get total sets across all workouts
    final totalSets = workouts.fold(0, (sum, w) => sum + w.totalSets);
    
    return GestureDetector(
      onTap: () {
        // If only one workout, go directly to it
        if (workouts.length == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(workout: workouts.first),
            ),
          );
        } else {
          // If multiple workouts, show first one (can enhance later to show list)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(workout: workouts.first),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(date),
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (workouts.length > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${workouts.length}x',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$totalSets sets • ${allExercises.join(' • ')}',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      color: AppColors.accent.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.accent.withOpacity(0.4),
              size: 24,
            ),
          ],
        ),
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
    } else {
      // Show exact date for anything older than yesterday
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
    if (data.isEmpty || data.length == 1) {
      return;
    }

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Find min and max for scaling
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
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
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
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
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MiniChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

