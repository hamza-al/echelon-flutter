import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../styles.dart';
import '../services/sleep_service.dart';
import 'nutrition_screen.dart';

class HealthScreen extends StatefulWidget {
  final int initialSubTab;

  const HealthScreen({super.key, this.initialSubTab = 0});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  late int _currentTab = widget.initialSubTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _SegmentedTabs(
                selected: _currentTab,
                onChanged: (i) => setState(() => _currentTab = i),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  NutritionScreen(embedded: true),
                  _SleepTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _pill('Nutrition', 0),
          _pill('Sleep', 1),
        ],
      ),
    );
  }

  Widget _pill(String label, int index) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active
                ? AppColors.overlay.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.overlay.withValues(alpha: 0.85)
                    : AppColors.overlay.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep Tab
// ---------------------------------------------------------------------------

class _SleepTab extends StatefulWidget {
  const _SleepTab();

  @override
  State<_SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<_SleepTab> {
  List<SleepEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() => _logs = SleepService.getAllLogs());
  }

  bool get _hasData => _logs.isNotEmpty;
  SleepEntry? get _lastLog => _hasData ? _logs.first : null;

  String _statusTitle(double hours) {
    if (hours >= 7 && hours <= 9) return 'Well rested';
    if (hours >= 6) return 'Could be better';
    return 'Sleep deprived';
  }

  String _statusSubtitle(double hours) {
    if (hours >= 7 && hours <= 9) {
      return '${hours.toStringAsFixed(1)}h — right in the sweet spot.';
    }
    if (hours >= 6) {
      return '${hours.toStringAsFixed(1)}h — try to get a bit more.';
    }
    return '${hours.toStringAsFixed(1)}h — aim for 7–9 hours.';
  }

  double get _weekAvg {
    if (_logs.isEmpty) return 0;
    final recent = _logs.take(7);
    return recent.map((l) => l.hours).reduce((a, b) => a + b) / recent.length;
  }

  double get _monthAvg {
    if (_logs.isEmpty) return 0;
    final recent = _logs.take(30);
    return recent.map((l) => l.hours).reduce((a, b) => a + b) / recent.length;
  }

  double get _bestNight {
    if (_logs.isEmpty) return 0;
    return _logs.map((l) => l.hours).reduce((a, b) => a > b ? a : b);
  }

  void _openLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SleepSheet(
        onSave: (entry) async {
          await SleepService.addLog(entry);
          _loadLogs();
        },
      ),
    );
  }

  void _openEditSheet() {
    final log = _lastLog;
    if (log == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SleepSheet(
        isEdit: true,
        editId: log.id,
        initialBedtime: TimeOfDay(hour: log.bedtimeHour, minute: log.bedtimeMinute),
        initialWake: TimeOfDay(hour: log.wakeHour, minute: log.wakeMinute),
        initialQualityIndex: log.qualityIndex,
        onSave: (entry) async {
          await SleepService.updateLog(entry);
          _loadLogs();
        },
      ),
    );
  }

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep',
                      style: AppStyles.mainHeader().copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 16),

                    // Status banner
                    if (_hasData)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 28,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusTitle(_lastLog!.hours),
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _statusSubtitle(_lastLog!.hours),
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!_hasData)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 28,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No data yet',
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap + to log your first night and start seeing insights.',
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Last night card or prompt
                    if (_hasData)
                      _buildLastNightCard()
                    else
                      GestureDetector(
                        onTap: _openLogSheet,
                        child: _card(
                          child: Column(
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                size: 28,
                                color: AppColors.primaryLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'How did you sleep?',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      AppColors.overlay.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to log last night',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 13,
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Stats row
                    if (_hasData) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statChip(
                              '${_weekAvg.toStringAsFixed(1)}h', '7-day avg'),
                          const SizedBox(width: 8),
                          _statChip('${_monthAvg.toStringAsFixed(1)}h',
                              '30-day avg'),
                          const SizedBox(width: 8),
                          _statChip('${_bestNight.toStringAsFixed(1)}h',
                              'Best night'),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // This week chart
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THIS WEEK',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppColors.overlay.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _hasData
                              ? _buildWeekChart()
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Text(
                                      'Your weekly chart will appear here.',
                                      style: AppStyles.mainText().copyWith(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 30-day trend heatmap
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '30-DAY TREND',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppColors.overlay.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildHeatmap(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // FAB
        Positioned(
          right: 24,
          bottom: 100,
          child: GestureDetector(
            onTap: _openLogSheet,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastNightCard() {
    final log = _lastLog!;
    final hours = log.hours;
    final bedtime = log.bedtimeFormatted;
    final wake = log.wakeFormatted;
    final quality = log.quality;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAST NIGHT',
                style: AppStyles.mainText().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.overlay.withValues(alpha: 0.2),
                ),
              ),
              GestureDetector(
                onTap: _openEditSheet,
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.overlay.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _SleepRingPainter(hours: hours, maxHours: 12),
                  child: Center(
                    child: Text(
                      '${hours.round()}h',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconRow(Icons.nightlight_round, bedtime),
                  const SizedBox(height: 8),
                  _iconRow(Icons.wb_sunny_rounded, wake),
                  const SizedBox(height: 8),
                  _iconRow(Icons.star_rounded, quality),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppStyles.mainText().copyWith(
            fontSize: 14,
            color: AppColors.overlay.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekChart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final weekLogs = List<double?>.filled(7, null);

    for (final log in _logs) {
      final diff = now.difference(log.date).inDays;
      if (diff < 7) {
        final idx = (log.date.weekday - 1) % 7;
        weekLogs[idx] ??= log.hours;
      }
    }

    const double chartH = 80;

    return Column(
      children: [
        SizedBox(
          height: chartH + 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final val = weekLogs[i];
              final isToday = i == (weekday - 1) % 7;
              final barH = val != null
                  ? (val / 12.0 * chartH).clamp(6.0, chartH)
                  : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (val != null)
                        Text(
                          '${val.toStringAsFixed(1)}',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 10,
                            color: AppColors.primaryLight
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      if (val != null) const SizedBox(height: 4),
                      val != null
                          ? Container(
                              height: barH,
                              width: 28,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.primaryLight
                                        .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          : Container(
                              height: 2,
                              width: 20,
                              decoration: BoxDecoration(
                                color: AppColors.overlay
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final isToday = i == (weekday - 1) % 7;
            return Expanded(
              child: Center(
                child: Text(
                  _dayLabels[i],
                  style: AppStyles.mainText().copyWith(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isToday
                        ? AppColors.overlay.withValues(alpha: 0.5)
                        : AppColors.overlay.withValues(alpha: 0.15),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.overlay.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppStyles.mainText().copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 11,
                color: AppColors.overlay.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayMap = <int, double>{};
    for (final log in _logs) {
      final d = DateTime(log.date.year, log.date.month, log.date.day);
      final daysAgo = today.difference(d).inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        dayMap[daysAgo] ??= log.hours;
      }
    }

    final cells = List.generate(30, (i) {
      final daysAgo = 29 - i;
      return dayMap[daysAgo];
    });

    const cols = 10;
    const rows = 3;
    const spacing = 3.0;

    Color cellColor(double? hours) {
      if (hours == null) {
        return AppColors.overlay.withValues(alpha: 0.04);
      }
      if (hours >= 8) return AppColors.primaryDark;
      if (hours >= 7) return AppColors.primaryLight;
      if (hours >= 6) return AppColors.primaryLight.withValues(alpha: 0.55);
      if (hours >= 4) return AppColors.primaryLight.withValues(alpha: 0.30);
      return AppColors.primaryLight.withValues(alpha: 0.15);
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cellSize =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(rows * cols, (i) {
                final val = i < 30 ? cells[i] : null;
                final daysAgo = 29 - i;
                final isToday = i == 29;
                return Tooltip(
                  message: val != null
                      ? '${val.toStringAsFixed(1)}h${isToday ? " (today)" : ""}'
                      : daysAgo >= 0
                          ? 'No data'
                          : '',
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: cellColor(val),
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                          ? Border.all(
                              color: AppColors.primaryLight,
                              width: 1.5,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _logs.isNotEmpty
                  ? 'Avg ${_monthAvg.toStringAsFixed(1)}h · ${dayMap.length} of 30 nights'
                  : 'Log nights to see your trend.',
              style: AppStyles.mainText().copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            Row(
              children: [
                Text(
                  'Less',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                ...List.generate(4, (i) {
                  final alphas = [0.04, 0.20, 0.50, 1.0];
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: i == 3
                          ? AppColors.primaryDark
                          : AppColors.primaryLight.withValues(
                              alpha: alphas[i]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 2),
                Text(
                  'More',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Log / Edit Sleep Bottom Sheet
// ---------------------------------------------------------------------------

class _SleepSheet extends StatefulWidget {
  final bool isEdit;
  final String? editId;
  final TimeOfDay? initialBedtime;
  final TimeOfDay? initialWake;
  final int? initialQualityIndex;
  final ValueChanged<SleepEntry> onSave;

  const _SleepSheet({
    this.isEdit = false,
    this.editId,
    this.initialBedtime,
    this.initialWake,
    this.initialQualityIndex,
    required this.onSave,
  });

  @override
  State<_SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<_SleepSheet> {
  late TimeOfDay _bedtime;
  late TimeOfDay _wakeUp;
  late int _qualityIndex;

  static const _qualityLabels = ['Terrible', 'Poor', 'Fair', 'Good', 'Great'];

  @override
  void initState() {
    super.initState();
    _bedtime = widget.initialBedtime ?? const TimeOfDay(hour: 23, minute: 0);
    _wakeUp = widget.initialWake ?? const TimeOfDay(hour: 8, minute: 0);
    _qualityIndex = widget.initialQualityIndex ?? 3;
  }

  double get _hours {
    final bedMinutes = _bedtime.hour * 60 + _bedtime.minute;
    final wakeMinutes = _wakeUp.hour * 60 + _wakeUp.minute;
    var diff = wakeMinutes - bedMinutes;
    if (diff <= 0) diff += 24 * 60;
    return diff / 60.0;
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime({required bool isBedtime}) async {
    final initial = isBedtime ? _bedtime : _wakeUp;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        TimeOfDay picked = initial;
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isBedtime) {
                            _bedtime = picked;
                          } else {
                            _wakeUp = picked;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Done',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: AppColors.isDark
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime:
                        DateTime(2024, 1, 1, initial.hour, initial.minute),
                    use24hFormat: false,
                    onDateTimeChanged: (dt) {
                      picked = TimeOfDay(hour: dt.hour, minute: dt.minute);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save() {
    final entry = SleepEntry(
      id: widget.editId ?? const Uuid().v4(),
      date: DateTime.now(),
      hours: _hours,
      quality: _qualityLabels[_qualityIndex],
      qualityIndex: _qualityIndex,
      bedtimeHour: _bedtime.hour,
      bedtimeMinute: _bedtime.minute,
      wakeHour: _wakeUp.hour,
      wakeMinute: _wakeUp.minute,
    );
    widget.onSave(entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.overlay.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.isEdit ? 'Edit Sleep' : 'Log Sleep',
              style: AppStyles.mainText().copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last night',
              style: AppStyles.mainText().copyWith(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _SleepRingPainter(hours: _hours, maxHours: 12),
                child: Center(
                  child: Text(
                    '${_hours.round()}h',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isBedtime: true),
                    child: _timeCard(
                      icon: Icons.nightlight_round,
                      label: 'BEDTIME',
                      value: _formatTime(_bedtime),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isBedtime: false),
                    child: _timeCard(
                      icon: Icons.wb_sunny_rounded,
                      label: 'WAKE UP',
                      value: _formatTime(_wakeUp),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'QUALITY',
                style: AppStyles.mainText().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.overlay.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final selected = _qualityIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _qualityIndex = i),
                    child: Container(
                      margin: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        right: i == 4 ? 0 : 4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryLight
                                .withValues(alpha: 0.12)
                            : AppColors.overlay.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryLight
                                  .withValues(alpha: 0.25)
                              : AppColors.overlay.withValues(alpha: 0.06),
                          width: selected ? 1 : 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _qualityLabels[i],
                          style: AppStyles.mainText().copyWith(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? AppColors.overlay.withValues(alpha: 0.7)
                                : AppColors.overlay.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: widget.isEdit
                      ? AppColors.primaryLight.withValues(alpha: 0.6)
                      : AppColors.overlay.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: widget.isEdit
                      ? null
                      : Border.all(
                          color: AppColors.overlay.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                ),
                child: Center(
                  child: Text(
                    widget.isEdit ? 'Update' : 'Save',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isEdit
                          ? AppColors.overlay.withValues(alpha: 0.9)
                          : AppColors.overlay.withValues(alpha: 0.6),
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

  Widget _timeCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primaryLight.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppStyles.mainText().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.overlay.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppStyles.mainText().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.overlay.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep Ring Painter
// ---------------------------------------------------------------------------

class _SleepRingPainter extends CustomPainter {
  final double hours;
  final double maxHours;

  _SleepRingPainter({required this.hours, required this.maxHours});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final strokeWidth = size.width > 80 ? 8.0 : 4.0;

    final bgPaint = Paint()
      ..color = AppColors.overlay.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progress = (hours / maxHours).clamp(0.0, 1.0);
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = AppColors.primaryLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SleepRingPainter old) => old.hours != hours;
}
