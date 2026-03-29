import 'package:flutter/material.dart';
import '../../styles.dart';

class NutritionGoalStep extends StatefulWidget {
  final String? selectedGoal;
  final int targetCalories;
  final Function(String goal, int calories) onGoalSelected;

  const NutritionGoalStep({
    super.key,
    required this.selectedGoal,
    required this.targetCalories,
    required this.onGoalSelected,
  });

  @override
  State<NutritionGoalStep> createState() => _NutritionGoalStepState();
}

class _NutritionGoalStepState extends State<NutritionGoalStep> {
  late String? _selectedGoal;
  late int _targetCalories;

  final Map<String, int> _goalDefaults = {
    'cut': 1800,
    'bulk': 2500,
    'maintain': 2000,
  };

  final Map<String, String> _goalDescriptions = {
    'cut': 'Lose fat, keep muscle',
    'bulk': 'Build muscle, gain size',
    'maintain': 'Stay where you are',
  };

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.selectedGoal;
    _targetCalories = widget.targetCalories;
  }

  void _selectGoal(String goal) {
    setState(() {
      _selectedGoal = goal;
      _targetCalories = _goalDefaults[goal]!;
    });
    widget.onGoalSelected(goal, _targetCalories);
  }

  void _adjustCalories(int delta) {
    setState(() {
      _targetCalories = (_targetCalories + delta).clamp(1000, 5000);
    });
    if (_selectedGoal != null) {
      widget.onGoalSelected(_selectedGoal!, _targetCalories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Nutrition goal',
            style: AppStyles.questionText().copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'This shapes your daily targets',
            style: AppStyles.questionSubtext(),
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...['cut', 'bulk', 'maintain'].map((goal) {
                  final isSelected = _selectedGoal == goal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _selectGoal(goal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textPrimary.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.textPrimary.withValues(alpha: 0.25)
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal[0].toUpperCase() + goal.substring(1),
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _goalDescriptions[goal]!,
                                    style: AppStyles.caption().copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: isSelected ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.textPrimary,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_selectedGoal != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'DAILY TARGET',
                          style: AppStyles.label()
                              .copyWith(letterSpacing: 1.5, fontSize: 11),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _adjustCalories(-50),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceLight,
                                ),
                                child: const Icon(
                                  Icons.remove_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 28),
                            Text(
                              _targetCalories.toString(),
                              style: AppStyles.mainHeader().copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 28),
                            GestureDetector(
                              onTap: () => _adjustCalories(50),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceLight,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'calories per day',
                          style: AppStyles.caption(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
