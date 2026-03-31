import 'package:flutter/material.dart';
import '../styles.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredExercises = [];

  static const Map<String, List<String>> _exercisesByCategory = {
    'Chest': [
      'bench_press',
      'incline_bench_press',
      'decline_bench_press',
      'dumbbell_bench_press',
      'incline_dumbbell_press',
      'decline_dumbbell_press',
      'chest_fly',
      'dumbbell_fly',
      'cable_fly',
      'pec_deck',
      'push_up',
      'weighted_push_up',
      'dip',
      'chest_press_machine',
    ],
    'Back': [
      'deadlift',
      'romanian_deadlift',
      'stiff_leg_deadlift',
      'sumo_deadlift',
      'barbell_row',
      'pendlay_row',
      'dumbbell_row',
      'single_arm_dumbbell_row',
      'seated_row',
      'cable_row',
      'lat_pulldown',
      'wide_grip_lat_pulldown',
      'close_grip_lat_pulldown',
      'pull_up',
      'wide_grip_pull_up',
      'chin_up',
      'neutral_grip_pull_up',
      'face_pull',
      'straight_arm_pulldown',
      'back_extension',
    ],
    'Shoulders': [
      'shoulder_press',
      'overhead_press',
      'military_press',
      'dumbbell_shoulder_press',
      'arnold_press',
      'lateral_raise',
      'dumbbell_lateral_raise',
      'cable_lateral_raise',
      'front_raise',
      'rear_delt_fly',
      'reverse_pec_deck',
      'upright_row',
      'machine_shoulder_press',
    ],
    'Legs': [
      'squat',
      'back_squat',
      'front_squat',
      'box_squat',
      'pause_squat',
      'goblet_squat',
      'hack_squat',
      'leg_press',
      'single_leg_press',
      'lunges',
      'walking_lunge',
      'reverse_lunge',
      'bulgarian_split_squat',
      'step_up',
      'leg_extension',
      'seated_leg_curl',
      'lying_leg_curl',
      'standing_leg_curl',
      'romanian_deadlift',
      'hip_thrust',
      'barbell_hip_thrust',
      'glute_bridge',
      'smith_machine_squat',
    ],
    'Glutes': [
      'hip_thrust',
      'barbell_hip_thrust',
      'glute_bridge',
      'cable_kickback',
      'hip_abduction',
      'hip_adduction',
      'frog_pump',
      'step_up',
      'bulgarian_split_squat',
    ],
    'Calves': [
      'calf_raise',
      'standing_calf_raise',
      'seated_calf_raise',
      'single_leg_calf_raise',
      'donkey_calf_raise',
      'calf_press',
    ],
    'Biceps': [
      'bicep_curl',
      'barbell_curl',
      'ez_bar_curl',
      'dumbbell_curl',
      'alternating_dumbbell_curl',
      'hammer_curl',
      'cross_body_hammer_curl',
      'preacher_curl',
      'incline_dumbbell_curl',
      'cable_curl',
      'concentration_curl',
    ],
    'Triceps': [
      'tricep_extension',
      'overhead_tricep_extension',
      'dumbbell_tricep_extension',
      'cable_tricep_extension',
      'tricep_pushdown',
      'rope_pushdown',
      'skullcrusher',
      'lying_tricep_extension',
      'close_grip_bench_press',
      'dip',
    ],
    'Core': [
      'plank',
      'side_plank',
      'weighted_plank',
      'crunch',
      'cable_crunch',
      'hanging_leg_raise',
      'lying_leg_raise',
      'knee_raise',
      'ab_wheel',
      'sit_up',
      'russian_twist',
      'dead_bug',
      'pallof_press',
    ],
    'Conditioning': [
      'kettlebell_swing',
      'sled_push',
      'sled_pull',
      'farmer_carry',
      'battle_rope',
      'box_jump',
      'medicine_ball_slam',
    ],
    'Cardio': [
      'running',
      'jogging',
      'treadmill',
      'cycling',
      'stationary_bike',
      'rowing',
      'rowing_machine',
      'elliptical',
      'stair_climber',
      'jump_rope',
      'swimming',
    ],
    'Machines': [
      'smith_machine_press',
      'smith_machine_row',
      'assisted_pull_up',
      'assisted_dip',
      'machine_row',
      'machine_chest_press',
      'machine_leg_press',
    ],
  };

  @override
  void initState() {
    super.initState();
    _updateFilteredExercises('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _updateFilteredExercises(_searchController.text);
  }

  void _updateFilteredExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _exercisesByCategory.values
            .expand((exercises) => exercises)
            .toSet()
            .toList()
          ..sort();
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredExercises = _exercisesByCategory.values
            .expand((exercises) => exercises)
            .where((exercise) =>
                _formatExerciseName(exercise).toLowerCase().contains(lowerQuery))
            .toSet()
            .toList()
          ..sort();
      }
    });
  }

  String _formatExerciseName(String exercise) {
    return exercise
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String? _getCategoryForExercise(String exercise) {
    for (final entry in _exercisesByCategory.entries) {
      if (entry.value.contains(exercise)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Exercise',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppStyles.mainText().copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: AppStyles.mainText().copyWith(
                      fontSize: 15,
                      color: AppColors.overlay.withValues(alpha: 0.2),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.overlay.withValues(alpha: 0.25),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              FocusScope.of(context).requestFocus(FocusNode());
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.overlay.withValues(alpha: 0.25),
                              size: 18,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.overlay.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.overlay.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.overlay.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.overlay.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _filteredExercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises found',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 14,
                            color: AppColors.overlay.withValues(alpha: 0.25),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          final category = _getCategoryForExercise(exercise);

                          return GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context, exercise);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.overlay.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.overlay.withValues(alpha: 0.04),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatExerciseName(exercise),
                                          style:
                                              AppStyles.mainText().copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (category != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            category,
                                            style:
                                                AppStyles.mainText().copyWith(
                                              fontSize: 12,
                                              color: Colors.white
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color:
                                        AppColors.overlay.withValues(alpha: 0.15),
                                  ),
                                ],
                              ),
                            ),
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
}
