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
        .where((s) => s.splitType != 'Custom')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Training split',
            style: AppStyles.questionText().copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Choose what fits your schedule',
            style: AppStyles.questionSubtext(),
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            itemCount: splits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final split = splits[index];
              final isSelected = selectedSplit == split.splitType;

              return GestureDetector(
                onTap: () => onSplitSelected(split.splitType),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.textPrimary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
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
                              split.splitType,
                              style: AppStyles.mainText().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              split.dayNames
                                  .where((d) => d != 'Rest')
                                  .join(' · '),
                              style: AppStyles.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          decoration:  BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textPrimary,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.background,
                          ),
                        ),
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
