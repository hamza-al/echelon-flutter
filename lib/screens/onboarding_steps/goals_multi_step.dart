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
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.04;
    
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 160,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Choose your goals',
                style: AppStyles.questionText().copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: _goals.map((goal) => _GoalChip(
                  label: goal,
                  isSelected: _selectedGoals.contains(goal),
                  onTap: () => _toggleGoal(goal),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.accent.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : const Color(0xFF1A1A1A),
        ),
        child: Text(
          label,
          style: AppStyles.mainText().copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
            color: isSelected ? AppColors.accent : AppColors.accent.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

