import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles.dart';

class OnboardingProcessingScreen extends StatefulWidget {
  final String nutritionGoal; // 'cut', 'bulk', 'maintain'
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
    extends State<OnboardingProcessingScreen> {
  int _currentPhase = 0;
  bool _processingDone = false;
  bool _showPlan = false;
  bool _showButton = false;
  int _visiblePlanRows = 0;

  final List<_ProcessingPhase> _phases = [
    _ProcessingPhase('Analyzing your goals', Icons.track_changes),
    _ProcessingPhase('Calculating your macros', Icons.pie_chart_outline),
    _ProcessingPhase('Building your workout plan', Icons.fitness_center),
    _ProcessingPhase('Personalizing your experience', Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
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
    setState(() => _showPlan = true);

    for (int i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => _visiblePlanRows = i);
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

              // Plan summary
              if (_processingDone) ...[
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showPlan ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: AnimatedSlide(
                      offset: _showPlan
                          ? Offset.zero
                          : const Offset(0, 0.1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 28),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildPlanRow(
                                  index: 0,
                                  icon: Icons.local_fire_department_rounded,
                                  iconColor: const Color(0xFFFF6B35),
                                  value: '${widget.targetCalories}',
                                  unit: 'cal/day',
                                  label: _goalLabel,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.06),
                                    height: 1,
                                  ),
                                ),
                                _buildPlanRow(
                                  index: 1,
                                  icon: Icons.fitness_center_rounded,
                                  iconColor: AppColors.primaryLight,
                                  value: widget.splitName,
                                  unit: '',
                                  label:
                                      '${widget.trainingDays} days/week',
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.06),
                                    height: 1,
                                  ),
                                ),
                                _buildPlanRow(
                                  index: 2,
                                  icon: Icons.track_changes_rounded,
                                  iconColor: const Color(0xFF34D399),
                                  value: widget.goals.length > 2
                                      ? '${widget.goals.take(2).join(', ')} +${widget.goals.length - 2}'
                                      : widget.goals.join(', '),
                                  unit: '',
                                  label: 'Your goals',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildPlanRow({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
  }) {
    final isVisible = _visiblePlanRows > index;
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.text.withOpacity(0.45),
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
}

class _ProcessingPhase {
  final String label;
  final IconData icon;
  const _ProcessingPhase(this.label, this.icon);
}
