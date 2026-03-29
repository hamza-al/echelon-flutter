import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/onboarding_data.dart';
import '../services/user_service.dart';
import '../services/split_service.dart';
import '../models/workout_split.dart';
import 'onboarding_steps/gender_selection_step.dart';
import 'onboarding_steps/physical_data_step.dart';
import 'onboarding_steps/goals_multi_step.dart';
import 'onboarding_steps/nutrition_goal_step.dart';
import 'onboarding_steps/split_selection_step.dart';
import 'voice_demo_step.dart';
import 'paywall_screen.dart';
import 'onboarding_processing_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  final OnboardingData _onboardingData = OnboardingData();
  String? _lastFeedback;
  String? _selectedSplit;

  final int _totalSteps = 5;

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _onboardingData.goals.isNotEmpty;
      case 1:
        return _onboardingData.weight != null &&
            _onboardingData.height != null &&
            _onboardingData.weight!.isNotEmpty &&
            _onboardingData.height!.isNotEmpty;
      case 2:
        return true;
      case 3:
        return _onboardingData.nutritionGoal != null;
      case 4:
        return _selectedSplit != null;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    if (_canProceed() && _currentStep < _totalSteps - 1) {
      setState(() {
        _lastFeedback = _getFeedbackForStep(_currentStep);
        _currentStep++;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _lastFeedback = null;
          });
        }
      });
    } else if (_canProceed() && _currentStep == _totalSteps - 1) {
      _onComplete();
    }
  }

  String? _getFeedbackForStep(int step) {
    switch (step) {
      case 0:
        return _getGoalFeedback();
      case 1:
        return 'Perfect, this helps me dial things in.';
      case 2:
        return 'Got it.';
      case 3:
        return 'Great choice.';
      case 4:
        return 'Good pick.';
      default:
        return null;
    }
  }

  String _getGoalFeedback() {
    final goals = _onboardingData.goals;
    if (goals.length > 2) {
      return 'Nice. I\'ll help you with all of that.';
    } else if (goals.any((g) => g.toLowerCase().contains('muscle'))) {
      return 'Nice choice. This changes how I coach you.';
    } else if (goals.any((g) => g.toLowerCase().contains('fat'))) {
      return 'Got it. I\'ll keep you consistent.';
    } else if (goals.any((g) => g.toLowerCase().contains('stronger'))) {
      return 'Perfect. I\'ll push your limits.';
    }
    return 'Got it.';
  }

  void _onComplete() async {
    await UserService.updateFromOnboarding(
      gender: _onboardingData.gender,
      weight: _onboardingData.weight,
      height: _onboardingData.height,
      goals: _onboardingData.goals,
    );

    await UserService.updateNutritionGoals(
      goal: _onboardingData.nutritionGoal!,
      calories: _onboardingData.targetCalories,
    );

    if (_selectedSplit != null) {
      final selectedSplitObj = WorkoutSplit.getAllSplits()
          .firstWhere((s) => s.splitType == _selectedSplit);
      await SplitService.setSplit(selectedSplitObj);
    }

    final selectedSplitObj = WorkoutSplit.getAllSplits()
        .firstWhere((s) => s.splitType == _selectedSplit);
    final trainingDays =
        selectedSplitObj.dayNames.where((d) => d != 'Rest').length;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingProcessingScreen(
            nutritionGoal: _onboardingData.nutritionGoal ?? 'maintain',
            targetCalories: _onboardingData.targetCalories,
            splitName: _selectedSplit!,
            trainingDays: trainingDays,
            goals: _onboardingData.goals,
            onContinue: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => VoiceDemoStep(
                    onComplete: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return GoalsMultiStep(
          key: const ValueKey('goals'),
          selectedGoals: _onboardingData.goals,
          onGoalsSelected: (goals) {
            setState(() {
              _onboardingData.goals = goals;
            });
          },
        );
      case 1:
        return PhysicalDataStep(
          key: const ValueKey('physical'),
          initialWeight: _onboardingData.weight,
          initialHeight: _onboardingData.height,
          onWeightEntered: (weight) {
            setState(() {
              _onboardingData.weight = weight;
            });
          },
          onHeightEntered: (height) {
            setState(() {
              _onboardingData.height = height;
            });
          },
        );
      case 2:
        return GenderSelectionStep(
          key: const ValueKey('gender'),
          selectedGender: _onboardingData.gender,
          onGenderSelected: (gender) {
            setState(() {
              _onboardingData.gender = gender;
            });
          },
        );
      case 3:
        return NutritionGoalStep(
          key: const ValueKey('nutrition'),
          selectedGoal: _onboardingData.nutritionGoal,
          targetCalories: _onboardingData.targetCalories,
          onGoalSelected: (goal, calories) {
            setState(() {
              _onboardingData.nutritionGoal = goal;
              _onboardingData.targetCalories = calories;
            });
          },
        );
      case 4:
        return SplitSelectionStep(
          key: const ValueKey('split'),
          selectedSplit: _selectedSplit,
          onSplitSelected: (split) {
            setState(() {
              _selectedSplit = split;
            });
          },
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 4),
              if (_currentStep > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _previousStep,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 44),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ),
              Column(
                children: [
                  if (_lastFeedback != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        _lastFeedback!,
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed() ? _nextStep : null,
                      style: AppStyles.primaryButton(),
                      child: Text(
                        (_currentStep == 2 && _onboardingData.gender == null)
                            ? 'Skip'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isActive
                  ? AppColors.textPrimary
                  : isDone
                      ? AppColors.textPrimary.withValues(alpha: 0.25)
                      : AppColors.surfaceLight,
            ),
          );
        }),
      ),
    );
  }
}
