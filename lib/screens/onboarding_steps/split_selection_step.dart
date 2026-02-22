import 'package:flutter/material.dart';
import '../../styles.dart';
import '../../models/workout_split.dart';

class SplitSelectionStep extends StatelessWidget {
  final String? selectedSplit;
  final Function(String) onSplitSelected;

  const SplitSelectionStep({
    super.key,
    required this.selectedSplit,
    required this.onSplitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final splits = WorkoutSplit.getAllSplits()
        .where((s) => s.splitType != 'Custom') // Exclude custom from onboarding
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose Your Split',
          style: AppStyles.mainHeader().copyWith(fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Select a training schedule that fits your goals',
          style: AppStyles.questionSubtext().copyWith(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Expanded(
          child: ListView.builder(
            itemCount: splits.length,
            itemBuilder: (context, index) {
              final split = splits[index];
              final isSelected = selectedSplit == split.splitType;
              
              return GestureDetector(
                onTap: () => onSplitSelected(split.splitType),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primaryLight.withOpacity(0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primaryLight 
                          : AppColors.accent.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Purple tab
                      Container(
                        width: 3,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primaryLight 
                              : Colors.transparent,
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
                              split.splitType,
                              style: AppStyles.mainText().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected 
                                    ? AppColors.primaryLight 
                                    : AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              split.dayNames.where((d) => d != 'Rest').join(' • '),
                              style: AppStyles.mainText().copyWith(
                                fontSize: 12,
                                color: AppColors.accent.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryLight,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
