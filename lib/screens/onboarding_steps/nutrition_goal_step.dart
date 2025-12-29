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
    'cut': 'Lose fat while maintaining muscle',
    'bulk': 'Build muscle and gain weight',
    'maintain': 'Maintain current weight',
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
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.02),
          
          // Title
          Text(
            'Nutrition Goal',
            style: AppStyles.questionText(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your goal',
            style: AppStyles.questionSubtext(),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: screenHeight * 0.04),
          
          // Goal options
          ...['cut', 'bulk', 'maintain'].map((goal) {
            final isSelected = _selectedGoal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectGoal(goal),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.accent.withOpacity(0.15),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.toUpperCase(),
                              style: AppStyles.mainText().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _goalDescriptions[goal]!,
                              style: AppStyles.questionSubtext().copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          if (_selectedGoal != null) ...[
            SizedBox(height: screenHeight * 0.04),
            
            // Calorie adjuster
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Daily Calorie Target',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _adjustCalories(-50),
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.accent.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        _targetCalories.toString(),
                        style: AppStyles.mainText().copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => _adjustCalories(50),
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.accent.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'calories per day',
                    style: AppStyles.questionSubtext().copyWith(
                      fontSize: 13,
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
}

