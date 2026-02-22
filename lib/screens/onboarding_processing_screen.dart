import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../styles.dart';

class OnboardingProcessingScreen extends StatefulWidget {
  final String nutritionGoal; // 'cut', 'bulk', 'maintain'
  final VoidCallback onContinue;

  const OnboardingProcessingScreen({
    super.key,
    required this.nutritionGoal,
    required this.onContinue,
  });

  @override
  State<OnboardingProcessingScreen> createState() =>
      _OnboardingProcessingScreenState();
}

class _OnboardingProcessingScreenState
    extends State<OnboardingProcessingScreen> with TickerProviderStateMixin {
  int _currentPhase = 0;
  bool _processingDone = false;
  bool _showGraph = false;
  bool _showStat = false;
  bool _showButton = false;

  late AnimationController _graphAnimController;
  late Animation<double> _graphProgress;

  final List<_ProcessingPhase> _phases = [
    _ProcessingPhase('Analyzing your goals', Icons.track_changes),
    _ProcessingPhase('Calculating your macros', Icons.pie_chart_outline),
    _ProcessingPhase('Building your workout plan', Icons.fitness_center),
    _ProcessingPhase('Personalizing your experience', Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    _graphAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _graphProgress = CurvedAnimation(
      parent: _graphAnimController,
      curve: Curves.easeOutCubic,
    );
    _runProcessing();
  }

  Future<void> _runProcessing() async {
    for (int i = 0; i < _phases.length; i++) {
      if (!mounted) return;
      setState(() => _currentPhase = i);
      await Future.delayed(Duration(milliseconds: 900 + (i * 200)));
    }

    if (!mounted) return;
    setState(() => _processingDone = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showGraph = true);
    _graphAnimController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showStat = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showButton = true);
  }

  @override
  void dispose() {
    _graphAnimController.dispose();
    super.dispose();
  }

  String get _graphTitle {
    switch (widget.nutritionGoal) {
      case 'cut':
        return 'Your weight';
      case 'bulk':
        return 'Your strength';
      case 'maintain':
      default:
        return 'Your fitness';
    }
  }

  String get _statLine {
    switch (widget.nutritionGoal) {
      case 'cut':
        return 'Users who stay consistent with Echelon maintain their results 3x longer';
      case 'bulk':
        return 'Echelon users see 40% more strength gains with structured coaching';
      case 'maintain':
      default:
        return 'Echelon users are 2.5x more likely to stay consistent after 6 months';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _processingDone
                      ? 'Your plan is ready'
                      : 'Building your plan',
                  key: ValueKey(_processingDone),
                  style: AppStyles.mainHeader().copyWith(fontSize: 34),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Processing steps
              if (!_processingDone) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _phases.length; i++)
                        _buildPhaseRow(i),
                    ],
                  ),
                ),
              ],

              // Graph + stat
              if (_processingDone) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Graph card
                      AnimatedOpacity(
                        opacity: _showGraph ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 700),
                        child: AnimatedSlide(
                          offset: _showGraph
                              ? Offset.zero
                              : const Offset(0, 0.1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _graphTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 180,
                                  child: AnimatedBuilder(
                                    animation: _graphProgress,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        size: const Size(double.infinity, 180),
                                        painter: _ProgressGraphPainter(
                                          progress: _graphProgress.value,
                                          nutritionGoal: widget.nutritionGoal,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Legend
                                Row(
                                  children: [
                                    _buildLegendDot(
                                      AppColors.primaryLight,
                                      'With Echelon',
                                    ),
                                    const SizedBox(width: 20),
                                    _buildLegendDot(
                                      Colors.red.shade400,
                                      'Without coaching',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Time labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Month 1',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color:
                                            AppColors.text.withOpacity(0.4),
                                      ),
                                    ),
                                    Text(
                                      'Month 6',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color:
                                            AppColors.text.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stat line
                      AnimatedOpacity(
                        opacity: _showStat ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _statLine,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text.withOpacity(0.6),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Continue button
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showButton ? widget.onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Try Voice Demo',
                        style: AppStyles.mainText().copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseRow(int index) {
    final isActive = index == _currentPhase;
    final isDone = index < _currentPhase;
    final isVisible = index <= _currentPhase;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.4),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isDone
                    ? Icon(
                        Icons.check_circle,
                        key: const ValueKey('done'),
                        color: AppColors.primaryLight,
                        size: 24,
                      )
                    : isActive
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryLight,
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('pending'),
                            width: 24,
                            height: 24,
                          ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _phases[index].label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isDone
                        ? AppColors.text.withOpacity(0.6)
                        : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.text.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _ProcessingPhase {
  final String label;
  final IconData icon;
  const _ProcessingPhase(this.label, this.icon);
}

class _ProgressGraphPainter extends CustomPainter {
  final double progress;
  final String nutritionGoal;

  _ProgressGraphPainter({
    required this.progress,
    required this.nutritionGoal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dashed baseline
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < w; x += 8) {
      canvas.drawLine(
        Offset(x, h * 0.5),
        Offset(x + 4, h * 0.5),
        dashPaint,
      );
    }

    // Generate curve points based on goal type
    final echelonPath = Path();
    final withoutPath = Path();

    final echelonPoints = _getEchelonPoints(w, h);
    final withoutPoints = _getWithoutPoints(w, h);

    // Draw up to `progress` fraction of the path
    final pointCount = (echelonPoints.length * progress).ceil().clamp(0, echelonPoints.length);
    if (pointCount < 2) return;

    // Echelon line
    echelonPath.moveTo(echelonPoints[0].dx, echelonPoints[0].dy);
    for (int i = 1; i < pointCount; i++) {
      final prev = echelonPoints[i - 1];
      final curr = echelonPoints[i];
      final cp1 = Offset(prev.dx + (curr.dx - prev.dx) * 0.5, prev.dy);
      final cp2 = Offset(prev.dx + (curr.dx - prev.dx) * 0.5, curr.dy);
      echelonPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    // Without coaching line
    withoutPath.moveTo(withoutPoints[0].dx, withoutPoints[0].dy);
    for (int i = 1; i < pointCount; i++) {
      final prev = withoutPoints[i - 1];
      final curr = withoutPoints[i];
      final cp1 = Offset(prev.dx + (curr.dx - prev.dx) * 0.5, prev.dy);
      final cp2 = Offset(prev.dx + (curr.dx - prev.dx) * 0.5, curr.dy);
      withoutPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }

    // Echelon fill (gradient area under/above the curve)
    final echelonFillPath = Path.from(echelonPath);
    final lastEchelon = echelonPoints[(pointCount - 1).clamp(0, echelonPoints.length - 1)];
    final firstEchelon = echelonPoints[0];
    echelonFillPath.lineTo(lastEchelon.dx, h);
    echelonFillPath.lineTo(firstEchelon.dx, h);
    echelonFillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFA78BFA).withOpacity(0.15),
          const Color(0xFFA78BFA).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(echelonFillPath, fillPaint);

    // Draw without-coaching line
    final withoutPaint = Paint()
      ..color = Colors.red.shade400.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(withoutPath, withoutPaint);

    // Draw echelon line
    final echelonPaint = Paint()
      ..color = const Color(0xFFA78BFA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(echelonPath, echelonPaint);

    // End dots
    if (pointCount >= 2) {
      canvas.drawCircle(
        lastEchelon,
        5,
        Paint()..color = const Color(0xFFA78BFA),
      );
      final lastWithout = withoutPoints[(pointCount - 1).clamp(0, withoutPoints.length - 1)];
      canvas.drawCircle(
        lastWithout,
        4,
        Paint()..color = Colors.red.shade400,
      );
    }
  }

  List<Offset> _getEchelonPoints(double w, double h) {
    switch (nutritionGoal) {
      case 'cut':
        // Weight drops steadily and stays low
        return [
          Offset(0, h * 0.25),
          Offset(w * 0.17, h * 0.35),
          Offset(w * 0.33, h * 0.50),
          Offset(w * 0.50, h * 0.62),
          Offset(w * 0.67, h * 0.70),
          Offset(w * 0.83, h * 0.75),
          Offset(w, h * 0.78),
        ];
      case 'bulk':
        // Strength/muscle goes up consistently
        return [
          Offset(0, h * 0.75),
          Offset(w * 0.17, h * 0.65),
          Offset(w * 0.33, h * 0.52),
          Offset(w * 0.50, h * 0.40),
          Offset(w * 0.67, h * 0.30),
          Offset(w * 0.83, h * 0.22),
          Offset(w, h * 0.18),
        ];
      case 'maintain':
      default:
        // Fitness improves steadily
        return [
          Offset(0, h * 0.55),
          Offset(w * 0.17, h * 0.48),
          Offset(w * 0.33, h * 0.40),
          Offset(w * 0.50, h * 0.35),
          Offset(w * 0.67, h * 0.30),
          Offset(w * 0.83, h * 0.27),
          Offset(w, h * 0.25),
        ];
    }
  }

  List<Offset> _getWithoutPoints(double w, double h) {
    switch (nutritionGoal) {
      case 'cut':
        // Weight drops then rebounds (yo-yo)
        return [
          Offset(0, h * 0.25),
          Offset(w * 0.17, h * 0.38),
          Offset(w * 0.33, h * 0.48),
          Offset(w * 0.50, h * 0.42),
          Offset(w * 0.67, h * 0.30),
          Offset(w * 0.83, h * 0.22),
          Offset(w, h * 0.18),
        ];
      case 'bulk':
        // Plateaus quickly
        return [
          Offset(0, h * 0.75),
          Offset(w * 0.17, h * 0.68),
          Offset(w * 0.33, h * 0.62),
          Offset(w * 0.50, h * 0.60),
          Offset(w * 0.67, h * 0.62),
          Offset(w * 0.83, h * 0.65),
          Offset(w, h * 0.68),
        ];
      case 'maintain':
      default:
        // Inconsistent, drifts
        return [
          Offset(0, h * 0.55),
          Offset(w * 0.17, h * 0.50),
          Offset(w * 0.33, h * 0.52),
          Offset(w * 0.50, h * 0.58),
          Offset(w * 0.67, h * 0.62),
          Offset(w * 0.83, h * 0.68),
          Offset(w, h * 0.72),
        ];
    }
  }

  @override
  bool shouldRepaint(_ProgressGraphPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
