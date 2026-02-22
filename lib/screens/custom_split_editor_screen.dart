import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/workout_split.dart';

class CustomSplitEditorScreen extends StatefulWidget {
  final WorkoutSplit? initialSplit;

  const CustomSplitEditorScreen({super.key, this.initialSplit});

  @override
  State<CustomSplitEditorScreen> createState() => _CustomSplitEditorScreenState();
}

class _CustomSplitEditorScreenState extends State<CustomSplitEditorScreen> {
  late List<String> _dayWorkouts;
  final List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  // Common workout options
  final List<String> _workoutOptions = [
    'Rest',
    'Push',
    'Pull',
    'Legs',
    'Upper',
    'Lower',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Full Body',
    'Cardio',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSplit != null && widget.initialSplit!.splitType == 'Custom') {
      _dayWorkouts = List.from(widget.initialSplit!.dayNames);
    } else {
      _dayWorkouts = ['Rest', 'Rest', 'Rest', 'Rest', 'Rest', 'Rest', 'Rest'];
    }
  }

  void _showWorkoutPicker(int dayIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Select Workout for ${_dayNames[dayIndex]}',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _workoutOptions.length,
                      itemBuilder: (context, index) {
                        final workout = _workoutOptions[index];
                        final isSelected = _dayWorkouts[dayIndex] == workout;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _dayWorkouts[dayIndex] = workout;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primaryLight.withOpacity(0.15)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primaryLight 
                                    : AppColors.accent.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryLight : Colors.transparent,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  workout,
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? AppColors.primaryLight : AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveSplit() {
    final customSplit = WorkoutSplit.custom(dayNames: _dayWorkouts);
    Navigator.of(context).pop(customSplit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.accent),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Custom Split',
                      style: AppStyles.mainHeader().copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Day list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 7,
                itemBuilder: (context, index) {
                  return _buildDayCard(index);
                },
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSplit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Custom Split',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(int index) {
    final workout = _dayWorkouts[index];
    final isRest = workout == 'Rest';

    return GestureDetector(
      onTap: () => _showWorkoutPicker(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Purple tab
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: isRest ? Colors.transparent : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Day name
            Expanded(
              child: Text(
                _dayNames[index],
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Workout badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isRest 
                    ? AppColors.accent.withOpacity(0.1) 
                    : AppColors.primaryLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                workout,
                style: AppStyles.mainText().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isRest 
                      ? AppColors.accent.withOpacity(0.5) 
                      : AppColors.primaryLight,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Icon(
              Icons.chevron_right,
              color: AppColors.accent.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
