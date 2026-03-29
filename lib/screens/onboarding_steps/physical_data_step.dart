import 'package:flutter/material.dart';
import '../../styles.dart';

class PhysicalDataStep extends StatefulWidget {
  final String? initialWeight;
  final String? initialHeight;
  final Function(String) onWeightEntered;
  final Function(String) onHeightEntered;

  const PhysicalDataStep({
    super.key,
    this.initialWeight,
    this.initialHeight,
    required this.onWeightEntered,
    required this.onHeightEntered,
  });

  @override
  State<PhysicalDataStep> createState() => _PhysicalDataStepState();
}

class _PhysicalDataStepState extends State<PhysicalDataStep> {
  int _weightLbs = 170;
  int _feet = 5;
  int _inches = 8;

  @override
  void initState() {
    super.initState();
    _parseInitialValues();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateValues();
    });
  }

  void _parseInitialValues() {
    if (widget.initialWeight != null) {
      final match = RegExp(r'(\d+)').firstMatch(widget.initialWeight!);
      if (match != null) {
        _weightLbs = int.tryParse(match.group(1)!) ?? 170;
      }
    }
    if (widget.initialHeight != null && widget.initialHeight!.contains("'")) {
      final parts = widget.initialHeight!.split("'");
      if (parts.length == 2) {
        _feet = int.tryParse(parts[0]) ?? 5;
        _inches = int.tryParse(parts[1].replaceAll('"', '').trim()) ?? 8;
      }
    }
  }

  void _updateValues() {
    widget.onWeightEntered('$_weightLbs lbs');
    widget.onHeightEntered("$_feet'$_inches\"");
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final pickerHeight = (screenHeight * 0.28).clamp(160.0, 220.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'About you',
            style: AppStyles.questionText().copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'For personalized coaching',
            style: AppStyles.questionSubtext(),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(child: _buildWeightPicker(pickerHeight)),
              const SizedBox(width: 20),
              Expanded(child: _buildHeightPicker(pickerHeight)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Text(
            'You can update this anytime',
            style: AppStyles.caption(),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildWeightPicker(double pickerHeight) {
    final itemExtent = (pickerHeight / 4).clamp(38.0, 48.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WEIGHT',
          style: AppStyles.label().copyWith(letterSpacing: 1.5, fontSize: 11),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: pickerHeight,
          child: ListWheelScrollView.useDelegate(
            itemExtent: itemExtent,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
              initialItem: (_weightLbs - 80).clamp(0, 200),
            ),
            onSelectedItemChanged: (index) {
              setState(() {
                _weightLbs = (index + 80).clamp(80, 400);
                _updateValues();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = index + 80;
                final isSelected = value == _weightLbs;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: AppStyles.mainText().copyWith(
                      fontSize: isSelected ? 28 : 17,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w300,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    child: Text('$value'),
                  ),
                );
              },
              childCount: 321,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('lbs', style: AppStyles.caption()),
      ],
    );
  }

  Widget _buildHeightPicker(double pickerHeight) {
    final itemExtent = (pickerHeight / 4).clamp(38.0, 48.0);
    const wheelWidth = 55.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'HEIGHT',
          style: AppStyles.label().copyWith(letterSpacing: 1.5, fontSize: 11),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: wheelWidth,
              height: pickerHeight,
              child: ListWheelScrollView.useDelegate(
                itemExtent: itemExtent,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                  initialItem: (_feet - 4).clamp(0, 4),
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _feet = (index + 4).clamp(4, 8);
                    _updateValues();
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final value = index + 4;
                    final isSelected = value == _feet;
                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: AppStyles.mainText().copyWith(
                          fontSize: isSelected ? 28 : 17,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w300,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                        child: Text('$value'),
                      ),
                    );
                  },
                  childCount: 5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('ft', style: AppStyles.caption()),
            ),
            SizedBox(
              width: wheelWidth,
              height: pickerHeight,
              child: ListWheelScrollView.useDelegate(
                itemExtent: itemExtent,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                  initialItem: _inches.clamp(0, 11),
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _inches = index.clamp(0, 11);
                    _updateValues();
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final isSelected = index == _inches;
                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: AppStyles.mainText().copyWith(
                          fontSize: isSelected ? 28 : 17,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w300,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                        child: Text('$index'),
                      ),
                    );
                  },
                  childCount: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('in', style: AppStyles.caption()),
            ),
          ],
        ),
      ],
    );
  }
}
