import 'package:flutter/material.dart';
import '../../styles.dart';

class GoalsMultiStep extends StatefulWidget {
  final List<String> selectedGoals;
  final Function(List<String>) onGoalsSelected;

  const GoalsMultiStep({
    super.key,
    required this.selectedGoals,
    required this.onGoalsSelected,
  });

  @override
  State<GoalsMultiStep> createState() => _GoalsMultiStepState();
}

class _GoalsMultiStepState extends State<GoalsMultiStep> {
  late Set<String> _selectedGoals;

  final List<String> _goals = [
    'Build muscle',
    'Lose fat',
    'Get stronger',
    'Improve form',
    'Stay consistent',
    'Increase endurance',
    'Improve mobility',
    'Better posture',
    'Athletic performance',
    'General health',
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoals = Set<String>.from(widget.selectedGoals);
  }

  void _toggleGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
    widget.onGoalsSelected(_selectedGoals.toList());
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
            'What drives you?',
            style: AppStyles.questionText().copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Select all that apply',
            style: AppStyles.questionSubtext(),
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _goals
                  .map((goal) => _GoalChip(
                        label: goal,
                        isSelected: _selectedGoals.contains(goal),
                        onTap: () => _toggleGoal(goal),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: isSelected
              ? AppColors.textPrimary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary.withValues(alpha: 0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.mainText().copyWith(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color:
                isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
