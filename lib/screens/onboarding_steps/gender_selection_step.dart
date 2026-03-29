import 'package:flutter/material.dart';
import '../../styles.dart';

class GenderSelectionStep extends StatefulWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const GenderSelectionStep({
    super.key,
    this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  State<GenderSelectionStep> createState() => _GenderSelectionStepState();
}

class _GenderSelectionStepState extends State<GenderSelectionStep> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.selectedGender;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPTIONAL',
                style:
                    AppStyles.label().copyWith(letterSpacing: 2, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Text(
                'Biological sex',
                style: AppStyles.questionText().copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                'Helps with calorie accuracy',
                style: AppStyles.questionSubtext(),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                label: 'Male',
                isSelected: _selectedGender == 'Male',
                onTap: () {
                  setState(() => _selectedGender = 'Male');
                  widget.onGenderSelected('Male');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GenderOption(
                label: 'Female',
                isSelected: _selectedGender == 'Female',
                onTap: () {
                  setState(() => _selectedGender = 'Female');
                  widget.onGenderSelected('Female');
                },
              ),
            ),
          ],
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
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
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppColors.textPrimary.withValues(alpha: 0.08)
              : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary.withValues(alpha: 0.25)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.mainText().copyWith(
            fontSize: 17,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color:
                isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
