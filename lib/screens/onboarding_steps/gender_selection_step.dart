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
            SizedBox(height: topPadding * 0.7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Text(
                    'Optional',
                    style: AppStyles.questionSubtext().copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For calorie estimates',
                    style: AppStyles.questionText().copyWith(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This helps with accuracy',
                    style: AppStyles.questionSubtext().copyWith(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _GenderOption(
                    label: 'Male',
                    isSelected: _selectedGender == 'Male',
                    onTap: () {
                      setState(() {
                        _selectedGender = 'Male';
                      });
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
                      setState(() {
                        _selectedGender = 'Female';
                      });
                      widget.onGenderSelected('Female');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.accent.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : const Color(0xFF1A1A1A),
        ),
        child: Text(
          label,
          style: AppStyles.mainText().copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
            color: isSelected ? AppColors.accent : AppColors.accent.withOpacity(0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

