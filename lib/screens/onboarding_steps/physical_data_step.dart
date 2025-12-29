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
    // Update values after first frame to ensure callbacks are ready
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
    final topPadding = screenHeight * 0.04;
    final pickerHeight = (screenHeight * 0.25).clamp(150.0, 180.0);
    
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
              child: Column(
                children: [
                  Text(
                    'Quick physical info',
                    style: AppStyles.questionText(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For personalized coaching',
                    style: AppStyles.questionSubtext(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildWeightPicker(pickerHeight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeightPicker(pickerHeight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can change this anytime',
              style: AppStyles.questionSubtext().copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightPicker(double pickerHeight) {
    final itemExtent = (pickerHeight / 4).clamp(35.0, 45.0);
    final selectedFontSize = (itemExtent * 0.65).clamp(24.0, 28.0);
    final unselectedFontSize = (itemExtent * 0.42).clamp(16.0, 18.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Weight',
          style: AppStyles.questionSubtext().copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
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
                  child: Text(
                    '$value',
                    style: AppStyles.mainText().copyWith(
                      fontSize: isSelected ? selectedFontSize : unselectedFontSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.accent.withOpacity(0.4),
                    ),
                  ),
                );
              },
              childCount: 321, // 80-400 lbs
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'lbs',
          style: AppStyles.questionSubtext().copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildHeightPicker(double pickerHeight) {
    final itemExtent = (pickerHeight / 4).clamp(35.0, 45.0);
    final selectedFontSize = (itemExtent * 0.65).clamp(24.0, 28.0);
    final unselectedFontSize = (itemExtent * 0.42).clamp(16.0, 18.0);
    final wheelWidth = (MediaQuery.of(context).size.width * 0.14).clamp(50.0, 65.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Height',
          style: AppStyles.questionSubtext().copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
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
                      child: Text(
                        '$value',
                        style: AppStyles.mainText().copyWith(
                          fontSize: isSelected ? selectedFontSize : unselectedFontSize,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.4),
                        ),
                      ),
                    );
                  },
                  childCount: 5, // 4-8 feet
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'ft',
                style: AppStyles.questionSubtext().copyWith(fontSize: 10),
              ),
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
                    final value = index;
                    final isSelected = value == _inches;
                    return Center(
                      child: Text(
                        '$value',
                        style: AppStyles.mainText().copyWith(
                          fontSize: isSelected ? selectedFontSize : unselectedFontSize,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.4),
                        ),
                      ),
                    );
                  },
                  childCount: 12, // 0-11 inches
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'in',
                style: AppStyles.questionSubtext().copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

