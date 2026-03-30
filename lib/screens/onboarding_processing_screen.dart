import 'dart:math';
import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';

class OnboardingProcessingScreen extends StatefulWidget {
  final String nutritionGoal;
  final int targetCalories;
  final String splitName;
  final int trainingDays;
  final List<String> goals;
  final VoidCallback onContinue;

  const OnboardingProcessingScreen({
    super.key,
    required this.nutritionGoal,
    required this.targetCalories,
    required this.splitName,
    required this.trainingDays,
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

    for (int i = 1; i <= 3; i++) {
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

  IconData get _goalIcon {
    switch (widget.nutritionGoal) {
      case 'cut':
        return Icons.local_fire_department_rounded;
      case 'bulk':
        return Icons.fitness_center_rounded;
      case 'maintain':
      default:
        return Icons.balance_rounded;
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
                _processingDone ? 'Your plan is ready' : 'Setting things up',
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
                        'Continue',
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

  Widget _buildPlanView() {
    return AnimatedOpacity(
      opacity: _showPlan ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: AnimatedSlide(
        offset: _showPlan ? Offset.zero : const Offset(0, 0.04),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlanCard(
                index: 0,
                icon: _goalIcon,
                title: '${widget.targetCalories} cal/day',
                subtitle: _goalLabel,
              ),
              const SizedBox(height: 10),
              _buildPlanCard(
                index: 1,
                icon: Icons.calendar_today_rounded,
                title: widget.splitName,
                subtitle: '${widget.trainingDays} days per week',
              ),
              const SizedBox(height: 10),
              _buildPlanCard(
                index: 2,
                icon: Icons.flag_rounded,
                title: widget.goals.length > 2
                    ? '${widget.goals.take(2).join(', ')} +${widget.goals.length - 2}'
                    : widget.goals.join(', '),
                subtitle: 'Your focus areas',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isVisible = _visibleCards > index;
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

