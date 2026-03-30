import 'dart:math';
import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';

class OnboardingProcessingScreen extends StatefulWidget {
  final String nutritionGoal;
  final int targetCalories;
  final String splitName;
  final int trainingDays;
  final List<String> dayNames;
  final List<String> goals;
  final VoidCallback onContinue;

  const OnboardingProcessingScreen({
    super.key,
    required this.nutritionGoal,
    required this.targetCalories,
    required this.splitName,
    required this.trainingDays,
    required this.dayNames,
    required this.goals,
    required this.onContinue,
  });

  @override
  State<OnboardingProcessingScreen> createState() =>
      _OnboardingProcessingScreenState();
}

class _OnboardingProcessingScreenState
    extends State<OnboardingProcessingScreen>
    with TickerProviderStateMixin {
  int _currentPhase = 0;
  bool _processingDone = false;
  bool _showPlan = false;
  bool _showButton = false;
  int _visibleCards = 0;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  final List<String> _phases = [
    'Analyzing your goals',
    'Calculating your macros',
    'Building your workout plan',
    'Personalizing your experience',
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );
    _progressCtrl.forward();
    _runProcessing();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _runProcessing() async {
    for (int i = 0; i < _phases.length; i++) {
      if (!mounted) return;
      setState(() => _currentPhase = i);
      await Future.delayed(Duration(milliseconds: 1000 + (i * 200)));
    }

    if (!mounted) return;
    setState(() => _processingDone = true);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _showPlan = true);

    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _visibleCards = i);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showButton = true);
  }

  String get _goalLabel {
    switch (widget.nutritionGoal) {
      case 'cut':
        return 'Fat loss';
      case 'bulk':
        return 'Muscle gain';
      case 'maintain':
      default:
        return 'Maintenance';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 48),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _processingDone
                    ? "Here's your game plan"
                    : 'Setting things up',
                key: ValueKey(_processingDone),
                style: AppStyles.mainText().copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (!_processingDone) ...[
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _phases[_currentPhase],
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],

            if (_processingDone) ...[
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: _showPlan ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Personalized to your body, your goals, and how you like to train.',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.35),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],

            Expanded(
              child: _processingDone ? _buildPlanView() : _buildLoadingView(),
            ),

            AnimatedOpacity(
              opacity: _showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
                child: GestureDetector(
                  onTap: _showButton ? widget.onContinue : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Let's go",
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
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

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const PulsingParticleSphere(size: 120),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) => CustomPaint(
                  size: const Size(180, 180),
                  painter: _ProgressRingPainter(
                    progress: _progressAnim.value,
                    phaseCount: _phases.length,
                    currentPhase: _currentPhase,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              for (int i = 0; i < _phases.length; i++)
                _buildPhaseRow(i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseRow(int index) {
    final isActive = index == _currentPhase;
    final isDone = index < _currentPhase;
    final isVisible = index <= _currentPhase;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      key: const ValueKey('done'),
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    )
                  : isActive
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        )
                      : SizedBox(
                          key: const ValueKey('pending'),
                          width: 16,
                          height: 16,
                          child: Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
            ),
            const SizedBox(width: 12),
            Text(
              _phases[index],
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isDone
                    ? Colors.white.withValues(alpha: 0.2)
                    : isActive
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> get _macros {
    final cal = widget.targetCalories;
    switch (widget.nutritionGoal) {
      case 'cut':
        return {
          'protein': (cal * 0.40 / 4).round(),
          'carbs': (cal * 0.30 / 4).round(),
          'fats': (cal * 0.30 / 9).round(),
        };
      case 'bulk':
        return {
          'protein': (cal * 0.30 / 4).round(),
          'carbs': (cal * 0.45 / 4).round(),
          'fats': (cal * 0.25 / 9).round(),
        };
      default:
        return {
          'protein': (cal * 0.30 / 4).round(),
          'carbs': (cal * 0.40 / 4).round(),
          'fats': (cal * 0.30 / 9).round(),
        };
    }
  }

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Widget _buildPlanView() {
    return AnimatedOpacity(
      opacity: _showPlan ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: AnimatedSlide(
        offset: _showPlan ? Offset.zero : const Offset(0, 0.04),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Weekly Schedule ---
              _animatedSection(
                index: 0,
                child: _buildSection(
                  label: 'YOUR WEEKLY SPLIT',
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(7, (i) {
                          final isRest = widget.dayNames[i] == 'Rest';
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: i == 0 ? 0 : 3,
                                right: i == 6 ? 0 : 3,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _weekdayLabels[i],
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: isRest ? 0.15 : 0.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isRest
                                          ? Colors.white.withValues(alpha: 0.02)
                                          : AppColors.primaryLight
                                              .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isRest
                                            ? Colors.white
                                                .withValues(alpha: 0.04)
                                            : AppColors.primaryLight
                                                .withValues(alpha: 0.18),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isRest ? '—' : widget.dayNames[i],
                                        style: AppStyles.mainText().copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isRest
                                              ? Colors.white
                                                  .withValues(alpha: 0.12)
                                              : AppColors.primaryLight
                                                  .withValues(alpha: 0.8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.splitName,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            '${widget.trainingDays} days/week',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // --- Section 2: Daily Nutrition ---
              _animatedSection(
                index: 1,
                child: _buildSection(
                  label: 'DAILY NUTRITION',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${widget.targetCalories}',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'cal/day',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _goalLabel,
                              style: AppStyles.mainText().copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.primaryLight.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _macroCell(
                              'Protein', '${_macros['protein']}g', 0.40),
                          const SizedBox(width: 8),
                          _macroCell('Carbs', '${_macros['carbs']}g', 0.35),
                          const SizedBox(width: 8),
                          _macroCell('Fats', '${_macros['fats']}g', 0.30),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // --- Section 3: Goals ---
              _animatedSection(
                index: 2,
                child: _buildSection(
                  label: 'YOUR FOCUS',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.goals.map((goal) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          goal,
                          style: AppStyles.mainText().copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // --- Section 4: What's included ---
              _animatedSection(
                index: 3,
                child: _buildSection(
                  label: "WHAT'S INCLUDED",
                  child: Column(
                    children: [
                      _includedRow(Icons.mic_none_rounded,
                          'Voice logging — say your sets, we track them'),
                      const SizedBox(height: 10),
                      _includedRow(Icons.auto_awesome,
                          'AI coach that adapts to your progress'),
                      const SizedBox(height: 10),
                      _includedRow(Icons.insights_rounded,
                          'Strength analytics and PR tracking'),
                      const SizedBox(height: 10),
                      _includedRow(Icons.notifications_active_rounded,
                          'Daily reminders with your workout'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedSection({required int index, required Widget child}) {
    final isVisible = _visibleCards > index;
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyles.mainText().copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _macroCell(String label, String value, double opacity) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _includedRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final int phaseCount;
  final int currentPhase;

  _ProgressRingPainter({
    required this.progress,
    required this.phaseCount,
    required this.currentPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.04);
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.2);

    final sweep = progress * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

