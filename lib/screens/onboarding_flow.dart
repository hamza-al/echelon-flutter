import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/onboarding_data.dart';
import '../services/user_service.dart';
import 'onboarding_steps/gender_selection_step.dart';
import 'onboarding_steps/physical_data_step.dart';
import 'onboarding_steps/goals_multi_step.dart';
import 'onboarding_steps/nutrition_goal_step.dart';
import 'voice_demo_step.dart';
import 'paywall_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  final OnboardingData _onboardingData = OnboardingData();
  String? _lastFeedback;

  // New order: Goals → Physical Data → Gender (optional) → Nutrition Goal → Voice Demo → Paywall
  final int _totalSteps = 4; // 0, 1, 2, 3 (voice demo shown separately after)

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Goals (multi-select)
        return _onboardingData.goals.isNotEmpty;
      case 1: // Physical Data
        return _onboardingData.weight != null && 
               _onboardingData.height != null &&
               _onboardingData.weight!.isNotEmpty &&
               _onboardingData.height!.isNotEmpty;
      case 2: // Gender (optional)
        return true; // Always can proceed, gender is optional
      case 3: // Nutrition Goal
        return _onboardingData.nutritionGoal != null;
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
      // Clear feedback after showing it
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
    // Save onboarding data to Hive (including nutrition goals)
    await UserService.updateFromOnboarding(
      gender: _onboardingData.gender,
      weight: _onboardingData.weight,
      height: _onboardingData.height,
      goals: _onboardingData.goals,
    );
    
    // Save nutrition goals
    await UserService.updateNutritionGoals(
      goal: _onboardingData.nutritionGoal!,
      calories: _onboardingData.targetCalories,
    );

    // Navigate to voice demo
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VoiceDemoStep(
            onComplete: () {
              // After voice demo, go to paywall
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const PaywallScreen(),
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
      case 0: // Goals (multi-select)
        return GoalsMultiStep(
          selectedGoals: _onboardingData.goals,
          onGoalsSelected: (goals) {
            setState(() {
              _onboardingData.goals = goals;
            });
          },
        );
      case 1: // Physical Data
        return PhysicalDataStep(
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
      case 2: // Gender (optional)
        return GenderSelectionStep(
          selectedGender: _onboardingData.gender,
          onGenderSelected: (gender) {
            setState(() {
              _onboardingData.gender = gender;
            });
          },
        );
      case 3: // Nutrition Goal
        return NutritionGoalStep(
          selectedGoal: _onboardingData.nutritionGoal,
          targetCalories: _onboardingData.targetCalories,
          onGoalSelected: (goal, calories) {
            setState(() {
              _onboardingData.nutritionGoal = goal;
              _onboardingData.targetCalories = calories;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              if (_currentStep > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.accent),
                    onPressed: _previousStep,
                    padding: EdgeInsets.zero,
                  ),
                )
              else
                const SizedBox(height: 48),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0.0),
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
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _lastFeedback!,
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (_currentStep >= 1 && _currentStep < 3) // Show language on later screens
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _currentStep == 2 ? 'Final step' : 'Almost ready',
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed() ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: AppColors.accent.withOpacity(0.3),
                      ),
                      child: Text(
                        _currentStep == _totalSteps - 1 
                            ? 'Try Voice Demo'
                            : (_currentStep == 2 && _onboardingData.gender == null)
                                ? 'Skip'
                                : 'Next',
                        style: AppStyles.mainText().copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
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
}

