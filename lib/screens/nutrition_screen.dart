import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/nutrition_store.dart';
import '../styles.dart';
import '../utils/macro_calculator.dart';
import '../services/user_service.dart';
import 'nutrition_history_screen.dart';
import 'add_food_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  void _showEditGoals(BuildContext context, NutritionStore nutritionStore) {
    final macroTargets = MacroCalculator.calculateTargets();
    final user = UserService.getCurrentUser();

    final calController = TextEditingController(
      text: (nutritionStore.targetCalories ?? 2000).toString(),
    );
    final proteinController = TextEditingController(
      text: (macroTargets['protein'] ?? 0).toStringAsFixed(0),
    );
    final carbsController = TextEditingController(
      text: (macroTargets['carbs'] ?? 0).toStringAsFixed(0),
    );
    final fatsController = TextEditingController(
      text: (macroTargets['fats'] ?? 0).toStringAsFixed(0),
    );

    final hasCustomMacros = user.customProtein != null || user.customCarbs != null || user.customFats != null;

    Widget buildField(String label, TextEditingController ctrl, String suffix, Color color) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyles.mainText().copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: AppStyles.mainText().copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: AppStyles.mainText().copyWith(
                fontSize: 13,
                color: AppColors.accent.withOpacity(0.5),
              ),
              filled: true,
              fillColor: color.withOpacity(0.08),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool customMode = hasCustomMacros;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Daily Goals',
              style: AppStyles.mainText().copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildField('Calories', calController, 'cal', AppColors.primaryLight),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Macros',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            customMode = !customMode;
                            if (!customMode) {
                              final defaults = MacroCalculator.calculateTargets();
                              proteinController.text = (defaults['protein'] ?? 0).toStringAsFixed(0);
                              carbsController.text = (defaults['carbs'] ?? 0).toStringAsFixed(0);
                              fatsController.text = (defaults['fats'] ?? 0).toStringAsFixed(0);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: customMode
                                ? AppColors.primaryLight.withOpacity(0.15)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            customMode ? 'Custom' : 'Auto',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 11,
                              color: customMode ? AppColors.primaryLight : AppColors.text.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: buildField('Protein', proteinController, 'g', const Color(0xFF6366F1))),
                      const SizedBox(width: 8),
                      Expanded(child: buildField('Carbs', carbsController, 'g', const Color(0xFFF59E0B))),
                      const SizedBox(width: 8),
                      Expanded(child: buildField('Fats', fatsController, 'g', const Color(0xFFEC4899))),
                    ],
                  ),
                  if (!customMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Based on your weight & goal',
                      style: AppStyles.questionSubtext().copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newCalories = int.tryParse(calController.text.trim());
                  if (newCalories != null && newCalories > 0) {
                    nutritionStore.updateTargetCalories(newCalories);
                  }

                  if (customMode) {
                    final p = double.tryParse(proteinController.text.trim());
                    final c = double.tryParse(carbsController.text.trim());
                    final f = double.tryParse(fatsController.text.trim());
                    UserService.updateCustomMacros(protein: p, carbs: c, fats: f);
                  } else {
                    UserService.updateCustomMacros(protein: null, carbs: null, fats: null);
                  }

                  nutritionStore.refreshToday();
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Save',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<NutritionStore>(
          builder: (context, nutritionStore, _) {
            // Check if user has set their nutrition goals
            if (!nutritionStore.hasSetGoals) {
              // Redirect to goal setup screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/nutrition_goal_setup');
              });
              
              // Show loading while redirecting
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }
            
            final macroTargets = MacroCalculator.calculateTargets();
            
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition',
                              style: AppStyles.mainHeader().copyWith(
                                fontSize: 30,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Today',
                              style: AppStyles.mainText().copyWith(
                                color: AppColors.text.withOpacity(0.6),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        // Subtle history button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NutritionHistoryScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: AppColors.text.withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'History',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 13,
                                    color: AppColors.text.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Calorie Ring (no background card)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _CalorieRing(
                      consumed: nutritionStore.totalCalories,
                      target: nutritionStore.targetCalories ?? 2000,
                      remaining: nutritionStore.remaining,
                      progress: nutritionStore.progress,
                      isOverGoal: nutritionStore.isOverGoal,
                      onTargetTap: () => _showEditGoals(context, nutritionStore),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                // Macro Rings Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditGoals(context, nutritionStore),
                            child: _MacroRing(
                              label: 'Protein',
                              current: nutritionStore.totalProtein,
                              target: macroTargets['protein'] ?? 0,
                              color: const Color(0xFF6366F1),
                              unit: 'g',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditGoals(context, nutritionStore),
                            child: _MacroRing(
                              label: 'Carbs',
                              current: nutritionStore.totalCarbs,
                              target: macroTargets['carbs'] ?? 0,
                              color: const Color(0xFFF59E0B),
                              unit: 'g',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditGoals(context, nutritionStore),
                            child: _MacroRing(
                              label: 'Fats',
                              current: nutritionStore.totalFats,
                              target: macroTargets['fats'] ?? 0,
                              color: const Color(0xFFEC4899),
                              unit: 'g',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                // Add Food Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddFoodScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: Text(
                          'Log Food',
                          style: AppStyles.mainText().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.primaryLight.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                // Meal entries header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Meals',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${nutritionStore.entries.length} entries',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 14,
                            color: AppColors.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Food entries list
                nutritionStore.entries.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.restaurant_outlined,
                                  size: 48,
                                  color: AppColors.text.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No meals logged yet',
                                  style: AppStyles.mainText().copyWith(
                                    color: AppColors.text.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = nutritionStore.entries[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                              child: Dismissible(
                                key: Key(entry.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.withOpacity(0.8),
                                  ),
                                ),
                                onDismissed: (_) {
                                  nutritionStore.deleteFood(entry.id);
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddFoodScreen(existingEntry: entry),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.text.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.name,
                                                style: AppStyles.mainText().copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    entry.timeFormatted,
                                                    style: AppStyles.mainText().copyWith(
                                                      fontSize: 13,
                                                      color: AppColors.text.withOpacity(0.5),
                                                    ),
                                                  ),
                                                  if (entry.protein != null || entry.carbs != null || entry.fats != null) ...[
                                                    Text(
                                                      ' • ',
                                                      style: AppStyles.mainText().copyWith(
                                                        fontSize: 13,
                                                        color: AppColors.text.withOpacity(0.5),
                                                      ),
                                                    ),
                                                    Text(
                                                      [
                                                        if (entry.protein != null) 'P:${entry.protein!.toStringAsFixed(0)}g',
                                                        if (entry.carbs != null) 'C:${entry.carbs!.toStringAsFixed(0)}g',
                                                        if (entry.fats != null) 'F:${entry.fats!.toStringAsFixed(0)}g',
                                                      ].join(' '),
                                                      style: AppStyles.mainText().copyWith(
                                                        fontSize: 12,
                                                        color: AppColors.text.withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${entry.calories} cal',
                                          style: GoogleFonts.inter(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: nutritionStore.entries.length,
                        ),
                      ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final int consumed;
  final int target;
  final int remaining;
  final double progress;
  final bool isOverGoal;
  final VoidCallback? onTargetTap;

  const _CalorieRing({
    required this.consumed,
    required this.target,
    required this.remaining,
    required this.progress,
    required this.isOverGoal,
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayTarget = target > 0 ? target : 2000;
    final safeProgress = target > 0 ? progress : 0.0;
    
    return Column(
      children: [
        // Ring
        SizedBox(
          height: 200,
          width: 200,
          child: CustomPaint(
            painter: _CalorieRingPainter(
              progress: safeProgress,
              isOverGoal: isOverGoal,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    consumed.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: isOverGoal ? Colors.orange : AppColors.text,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onTargetTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'of $displayTarget cal',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 14,
                            color: AppColors.text.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: AppColors.text.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Remaining
        Text(
          isOverGoal
              ? '${remaining.abs()} cal over'
              : '$remaining cal remaining',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isOverGoal
                ? Colors.orange
                : AppColors.text.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final bool isOverGoal;

  _CalorieRingPainter({
    required this.progress,
    required this.isOverGoal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    
    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.text.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = isOverGoal ? Colors.orange : AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isOverGoal != isOverGoal;
  }
}

class _MacroRing extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const _MacroRing({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - current).clamp(0, target);
    
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: CustomPaint(
            painter: _MacroRingPainter(
              progress: progress,
              color: color,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    current.toStringAsFixed(0),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    unit,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 10,
                      color: AppColors.text.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppStyles.mainText().copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${remaining.toStringAsFixed(0)}$unit left',
          style: AppStyles.mainText().copyWith(
            fontSize: 11,
            color: AppColors.text.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MacroRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    
    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.text.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MacroRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
