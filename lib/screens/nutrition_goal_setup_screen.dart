import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/nutrition_store.dart';
import '../styles.dart';
import 'package:google_fonts/google_fonts.dart';

class NutritionGoalSetupScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const NutritionGoalSetupScreen({super.key, this.onComplete});

  @override
  State<NutritionGoalSetupScreen> createState() => _NutritionGoalSetupScreenState();
}

class _NutritionGoalSetupScreenState extends State<NutritionGoalSetupScreen> {
  String? _selectedGoal;
  int _targetCalories = 2000;
  
  final Map<String, String> _goalDescriptions = {
    'cut': 'Lose fat while maintaining muscle',
    'bulk': 'Build muscle and gain weight',
    'maintain': 'Maintain current weight',
  };

  void _completeSetup() async {
    if (_selectedGoal == null) return;
    
    // Save to nutrition store (which saves to Hive via UserService)
    await context.read<NutritionStore>().setNutritionGoals(
      goal: _selectedGoal!,
      calories: _targetCalories,
    );
    
    // Either call onComplete callback or navigate to home
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              
              // Header
              Text(
                'Set your nutrition goal',
                style: AppStyles.pageHeader(),
              ),
              SizedBox(height: screenHeight * 0.01),
              
              Text(
                'This helps track your daily calorie target',
                style: AppStyles.questionSubtext().copyWith(
                  color: AppColors.text.withOpacity(0.6),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.05),
              
              // Goal options
              ..._goalDescriptions.entries.map((entry) {
                final isSelected = _selectedGoal == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGoal = entry.key;
                        // Suggest calories based on goal
                        if (entry.key == 'cut') {
                          _targetCalories = 1800;
                        } else if (entry.key == 'bulk') {
                          _targetCalories = 2500;
                        } else {
                          _targetCalories = 2000;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.text.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.value,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              color: AppColors.text.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Calorie target
              if (_selectedGoal != null) ...[
                Text(
                  'Daily calorie target',
                  style: AppStyles.questionText().copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                
                // Calorie picker
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.text.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_targetCalories cal/day',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _targetCalories = (_targetCalories - 50).clamp(1000, 5000);
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.primary,
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _targetCalories = (_targetCalories + 50).clamp(1000, 5000);
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(flex: 2),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedGoal != null ? _completeSetup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Center(
                child: Text(
                  'You can change this anytime',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 13,
                    color: AppColors.text.withOpacity(0.5),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

