import 'package:flutter/material.dart';
import '../styles.dart';

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
    extends State<OnboardingProcessingScreen> {
  int _currentPhase = 0;
  bool _processingDone = false;
  bool _showPlan = false;
  bool _showButton = false;
  int _visiblePlanRows = 0;

  final List<String> _phases = [
    'Analyzing your goals',
    'Calculating your macros',
    'Building your workout plan',
    'Personalizing your experience',
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
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _processingDone ? 'Your plan is ready' : 'Building your plan',
                  key: ValueKey(_processingDone),
                  style: AppStyles.questionText().copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

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

              if (_processingDone) ...[
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showPlan ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: AnimatedSlide(
                      offset:
                          _showPlan ? Offset.zero : const Offset(0, 0.06),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 28),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                _buildPlanRow(
                                  index: 0,
                                  value: '${widget.targetCalories}',
                                  unit: 'cal/day',
                                  label: _goalLabel,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(
                                    color: AppColors.border,
                                    height: 1,
                                  ),
                                ),
                                _buildPlanRow(
                                  index: 1,
                                  value: widget.splitName,
                                  unit: '',
                                  label: '${widget.trainingDays} days per week',
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(
                                    color: AppColors.border,
                                    height: 1,
                                  ),
                                ),
                                _buildPlanRow(
                                  index: 2,
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

              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showButton ? widget.onContinue : null,
                    style: AppStyles.primaryButton(),
                    child: const Text('Try Voice Demo'),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isDone
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('done'),
                        color: AppColors.textPrimary.withValues(alpha: 0.4),
                        size: 20,
                      )
                    : isActive
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('pending'),
                            width: 20,
                            height: 20,
                          ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _phases[index],
                  style: AppStyles.mainText().copyWith(
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    color: isDone
                        ? AppColors.textMuted
                        : isActive
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
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
                          style: AppStyles.mainText().copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: AppStyles.caption(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: AppStyles.caption(),
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
