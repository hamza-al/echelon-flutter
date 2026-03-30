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
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Split',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          final customSplit = await Navigator.of(context).push<WorkoutSplit>(
            MaterialPageRoute(
              builder: (context) => CustomSplitEditorScreen(
                initialSplit: _currentSplit.splitType == 'Custom'
                    ? _currentSplit
                    : null,
              ),
            ),
          );

          if (customSplit != null && mounted) {
            await SplitService.setSplit(customSplit);
            setState(() {
              _currentSplit = customSplit;
              _loadSchedule();
            });
            if (mounted) Navigator.of(context).pop();
          }
        } else {
          await SplitService.setSplit(split);
          setState(() {
            _currentSplit = split;
            _loadSchedule();
          });
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            width: 0.5,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCustom
                        ? 'Create your own schedule'
                        : split.dayNames
                            .where((d) => d != 'Rest')
                            .join(' · '),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              )
            else if (isCustom)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 20,
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Schedule',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentSplit.splitType,
                        style: AppStyles.mainText().copyWith(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            ..._weekSchedule.map((day) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDayCard(
                  date: day['date'] as DateTime,
                  dayName: day['dayName'] as String,
                  workout: day['workout'] as String,
                  isToday: day['isToday'] as bool,
                ),
              );
            }),

            const SizedBox(height: 24),

            // Change split button
            GestureDetector(
              onTap: _changeSplit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Change Split',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Split info
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About ${_currentSplit.splitType}',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSplitDescription(_currentSplit.splitType),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.35),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${date.day}',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? AppColors.textPrimary
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TODAY',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                Text(
                  workout,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    fontWeight: isRest ? FontWeight.w400 : FontWeight.w600,
                    color: isRest
                        ? Colors.white.withValues(alpha: 0.2)
                        : isToday
                            ? AppColors.textPrimary
                            : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
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
