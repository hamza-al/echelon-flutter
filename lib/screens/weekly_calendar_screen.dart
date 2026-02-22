import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/workout_split.dart';
import '../services/split_service.dart';
import 'custom_split_editor_screen.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  WorkoutSplit _currentSplit = SplitService.getCurrentSplit();
  List<Map<String, dynamic>> _weekSchedule = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() {
    setState(() {
      _weekSchedule = SplitService.getWeekSchedule();
    });
  }

  Future<void> _changeSplit() async {
    final allSplits = WorkoutSplit.getAllSplits();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
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
                      'Choose Your Split',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: allSplits.length,
                      itemBuilder: (context, index) {
                        return _buildSplitOption(allSplits[index]);
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

  Widget _buildSplitOption(WorkoutSplit split) {
    final isSelected = split.splitType == _currentSplit.splitType;
    final isCustom = split.splitType == 'Custom';
    
    return GestureDetector(
      onTap: () async {
        if (isCustom) {
          // Navigate to custom split editor
          final customSplit = await Navigator.of(context).push<WorkoutSplit>(
            MaterialPageRoute(
              builder: (context) => CustomSplitEditorScreen(
                initialSplit: _currentSplit.splitType == 'Custom' ? _currentSplit : null,
              ),
            ),
          );
          
          if (customSplit != null && mounted) {
            await SplitService.setSplit(customSplit);
            setState(() {
              _currentSplit = customSplit;
              _loadSchedule();
            });
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        } else {
          await SplitService.setSplit(split);
          setState(() {
            _currentSplit = split;
            _loadSchedule();
          });
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
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
            // Purple tab on the left
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    split.splitType,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primaryLight : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCustom 
                        ? 'Create your own schedule'
                        : split.dayNames.where((d) => d != 'Rest').join(' • '),
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
              )
            else if (isCustom)
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.accent.withOpacity(0.4),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.accent),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Schedule',
                        style: AppStyles.mainHeader().copyWith(
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentSplit.splitType,
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 14,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Vertically stacked day cards
            ..._weekSchedule.map((day) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDayCard(
                  date: day['date'] as DateTime,
                  dayName: day['dayName'] as String,
                  workout: day['workout'] as String,
                  isToday: day['isToday'] as bool,
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Change split button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _changeSplit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.accent.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Change Split',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Split info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About ${_currentSplit.splitType}',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSplitDescription(_currentSplit.splitType),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      color: AppColors.accent.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required DateTime date,
    required String dayName,
    required String workout,
    required bool isToday,
  }) {
    final isRest = workout == 'Rest';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday 
              ? AppColors.primaryLight 
              : AppColors.accent.withOpacity(0.2),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Purple tab on the left for non-today cards
          if (!isToday)
            Container(
              width: 3,
              height: 50,
              decoration: BoxDecoration(
                color: isRest 
                    ? Colors.transparent 
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          
          if (!isToday) const SizedBox(width: 16),
          
          // Date and day name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: AppStyles.mainText().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isToday 
                      ? AppColors.background 
                      : AppColors.accent.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day}',
                style: AppStyles.mainText().copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isToday ? AppColors.background : AppColors.accent,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Workout label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isToday 
                  ? AppColors.background.withOpacity(0.2) 
                  : (isRest 
                      ? AppColors.accent.withOpacity(0.1) 
                      : AppColors.primaryLight.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              workout,
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isToday 
                    ? AppColors.background 
                    : (isRest 
                        ? AppColors.accent.withOpacity(0.5) 
                        : AppColors.primaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSplitDescription(String splitType) {
    switch (splitType) {
      case 'Push/Pull/Legs':
        return 'Trains pushing muscles (chest, shoulders, triceps), pulling muscles (back, biceps), and legs separately. Great for frequency and recovery.';
      case 'Upper/Lower':
        return 'Alternates between upper body and lower body days. Perfect for beginners or those with limited training days.';
      case 'Bro Split':
        return 'Dedicates one day to each major muscle group. Classic bodybuilding approach for maximum focus per muscle.';
      case 'Full Body':
        return 'Trains all major muscle groups each session. Ideal for beginners or those training 3 days per week.';
      case 'Arnold Split':
        return 'Arnold Schwarzenegger\'s famous routine pairing chest with back, and shoulders with arms. High volume and intensity.';
      case 'Powerbuilding':
        return 'Combines powerlifting (heavy compounds) with bodybuilding (hypertrophy work). Best of both worlds.';
      case 'Custom':
        return 'Design your own split. Choose what to train each day of the week based on your goals and schedule.';
      default:
        return 'A structured training program to maximize your gains and recovery.';
    }
  }
}
