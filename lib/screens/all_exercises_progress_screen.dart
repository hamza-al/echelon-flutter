import 'package:flutter/material.dart';
import '../styles.dart';

class AllExercisesProgressScreen extends StatelessWidget {
  final Map<String, double> exercisePRs;
  final Map<String, int> exerciseMaxReps;
  final Map<String, DateTime> exercisePRDates;
  final Map<String, List<double>> exerciseVolumeHistory;
  final Map<String, List<DateTime>> exerciseWorkoutDates;
  final Map<String, List<double>> exerciseMaxWeightHistory;

  const AllExercisesProgressScreen({
    super.key,
    required this.exercisePRs,
    required this.exerciseMaxReps,
    required this.exercisePRDates,
    required this.exerciseVolumeHistory,
    required this.exerciseWorkoutDates,
    required this.exerciseMaxWeightHistory,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseFrequency = <String, int>{};
    for (var dates in exerciseWorkoutDates.entries) {
      exerciseFrequency[dates.key] = dates.value.length;
    }
    final sortedExercises = exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Exercises',
                          style: AppStyles.mainHeader().copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sortedExercises.length} tracked',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: sortedExercises.length,
                itemBuilder: (context, index) {
                  final name = sortedExercises[index].key;
                  final volumeData =
                      (exerciseVolumeHistory[name] ?? []).reversed.toList();
                  final weightData =
                      (exerciseMaxWeightHistory[name] ?? []).reversed.toList();
                  final dates =
                      (exerciseWorkoutDates[name] ?? []).reversed.toList();

                  bool hasUpwardTrend = false;
                  if (volumeData.length >= 2) {
                    final recent = volumeData.length >= 3
                        ? (volumeData[volumeData.length - 1] +
                                volumeData[volumeData.length - 2] +
                                volumeData[volumeData.length - 3]) /
                            3
                        : (volumeData[volumeData.length - 1] +
                                volumeData[volumeData.length - 2]) /
                            2;
                    final older = volumeData.length >= 4
                        ? (volumeData[0] + volumeData[1]) / 2
                        : volumeData[0];
                    hasUpwardTrend = recent > older;
                  }

                  double? weightIncrease;
                  if (weightData.length >= 2) {
                    final first = weightData.first;
                    final last = weightData.last;
                    if (first > 0) {
                      weightIncrease = ((last - first) / first) * 100;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _showDetail(
                          context, name, dates, volumeData, weightData),
                      child: _exerciseCard(
                        name: name,
                        sessions: dates.length,
                        hasUpwardTrend: hasUpwardTrend,
                        weightIncrease: weightIncrease,
                        volumeData: volumeData,
                        weightData: weightData,
                        pr: exercisePRs[name],
                        maxReps: exerciseMaxReps[name],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard({
    required String name,
    required int sessions,
    required bool hasUpwardTrend,
    required double? weightIncrease,
    required List<double> volumeData,
    required List<double> weightData,
    double? pr,
    int? maxReps,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fmt(name),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (pr != null) '${pr.toInt()} lbs',
                        '$sessions sessions',
                      ].join(' · '),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (weightIncrease != null && weightIncrease > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${weightIncrease.toStringAsFixed(0)}%',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                hasUpwardTrend ? Icons.trending_up : Icons.trending_flat,
                color: hasUpwardTrend
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.15),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: CustomPaint(
              painter: _ChartPainter(
                data: weightData.isNotEmpty ? weightData : volumeData,
                lineColor: Colors.white.withValues(alpha: 0.5),
                fillColor: Colors.white.withValues(alpha: 0.06),
              ),
              size: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    String name,
    List<DateTime> dates,
    List<double> volumeData,
    List<double> weightData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, sc) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fmt(name),
                            style:
                                AppStyles.mainHeader().copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dates.length} session${dates.length == 1 ? '' : 's'}',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final ri = dates.length - 1 - index;
                    final date = dates[ri];
                    final vol = ri < volumeData.length ? volumeData[ri] : null;
                    final wt = ri < weightData.length ? weightData[ri] : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session #${index + 1}',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _fmtDate(date),
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (wt != null && wt > 0)
                                Text(
                                  '${wt.toStringAsFixed(0)} lbs',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (wt != null && wt > 0 && vol != null && vol > 0)
                                Text(
                                  ' · ',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              if (vol != null && vol > 0)
                                Text(
                                  '${vol.toStringAsFixed(0)} vol',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(String name) {
    return name
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _fmtDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  _ChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final chartData = data.length == 1 ? [0.0, data.first] : data;

    final fPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final lPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final maxV = chartData.reduce((a, b) => a > b ? a : b);
    final minV = chartData.reduce((a, b) => a < b ? a : b);
    final range = maxV - minV;

    if (range == 0) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lPaint);
      return;
    }

    final pts = <Offset>[];
    final step = size.width / (chartData.length - 1);
    for (int i = 0; i < chartData.length; i++) {
      final x = i * step;
      final n = (chartData[i] - minV) / range;
      final y = size.height - (n * size.height * 0.85) - size.height * 0.05;
      pts.add(Offset(x, y));
    }

    final area = Path()
      ..moveTo(pts.first.dx, size.height)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      area.lineTo(pts[i].dx, pts[i].dy);
    }
    area.lineTo(pts.last.dx, size.height);
    area.close();
    canvas.drawPath(area, fPaint);

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(line, lPaint);

    final dot = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 2, dot);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.data != data || old.lineColor != lineColor;
}
