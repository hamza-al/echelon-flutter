import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/nutrition_store.dart';
import '../styles.dart';
import '../utils/macro_calculator.dart';
import '../services/user_service.dart';
import 'nutrition_history_screen.dart';
import 'add_food_screen.dart';
import 'dart:math' as math;

class NutritionScreen extends StatelessWidget {
  final bool embedded;
  const NutritionScreen({super.key, this.embedded = false});

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

    final hasCustomMacros = user.customProtein != null ||
        user.customCarbs != null ||
        user.customFats != null;

    Widget buildField(
        String label, TextEditingController ctrl, String suffix, Color color) {
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
            style: AppStyles.mainText()
                .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: AppStyles.mainText().copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: color.withValues(alpha: 0.08),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                  buildField('Calories', calController, 'cal',
                      AppColors.textPrimary),
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
                              final defaults =
                                  MacroCalculator.calculateTargets();
                              proteinController.text =
                                  (defaults['protein'] ?? 0)
                                      .toStringAsFixed(0);
                              carbsController.text =
                                  (defaults['carbs'] ?? 0).toStringAsFixed(0);
                              fatsController.text =
                                  (defaults['fats'] ?? 0).toStringAsFixed(0);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: customMode
                                ? AppColors.overlay.withValues(alpha: 0.12)
                                : AppColors.overlay.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            customMode ? 'Custom' : 'Auto',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 11,
                              color: customMode
                                  ? Colors.white
                                  : AppColors.textMuted,
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
                      Expanded(
                          child: buildField('Protein', proteinController, 'g',
                              const Color(0xFF6366F1))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: buildField('Carbs', carbsController, 'g',
                              const Color(0xFFF59E0B))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: buildField('Fats', fatsController, 'g',
                              const Color(0xFFEC4899))),
                    ],
                  ),
                  if (!customMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Based on your weight & goal',
                      style:
                          AppStyles.questionSubtext().copyWith(fontSize: 11),
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
                    color: AppColors.textSecondary,
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
                    final p =
                        double.tryParse(proteinController.text.trim());
                    final c = double.tryParse(carbsController.text.trim());
                    final f = double.tryParse(fatsController.text.trim());
                    UserService.updateCustomMacros(
                        protein: p, carbs: c, fats: f);
                  } else {
                    UserService.updateCustomMacros(
                        protein: null, carbs: null, fats: null);
                  }
                  nutritionStore.refreshToday();
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Save',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
    final body = Consumer<NutritionStore>(
          builder: (context, nutritionStore, _) {
            if (!nutritionStore.hasSetGoals) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context)
                    .pushReplacementNamed('/nutrition_goal_setup');
              });
              return const Center(
                child: CircularProgressIndicator(color: Colors.white24),
              );
            }

            final macroTargets = MacroCalculator.calculateTargets();

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nutrition',
                          style:
                              AppStyles.mainHeader().copyWith(fontSize: 30),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NutritionHistoryScreen(),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.history_rounded,
                            size: 22,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Calorie ring
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _CalorieRing(
                      consumed: nutritionStore.totalCalories,
                      target: nutritionStore.targetCalories ?? 2000,
                      remaining: nutritionStore.remaining,
                      progress: nutritionStore.progress,
                      isOverGoal: nutritionStore.isOverGoal,
                      onTargetTap: () =>
                          _showEditGoals(context, nutritionStore),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // Macro bars
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _showEditGoals(context, nutritionStore),
                            child: _MacroBar(
                              label: 'Protein',
                              current: nutritionStore.totalProtein,
                              target: macroTargets['protein'] ?? 0,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _showEditGoals(context, nutritionStore),
                            child: _MacroBar(
                              label: 'Carbs',
                              current: nutritionStore.totalCarbs,
                              target: macroTargets['carbs'] ?? 0,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _showEditGoals(context, nutritionStore),
                            child: _MacroBar(
                              label: 'Fats',
                              current: nutritionStore.totalFats,
                              target: macroTargets['fats'] ?? 0,
                              color: const Color(0xFFEC4899),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // Log Food button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddFoodScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.overlay.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.overlay.withValues(alpha: 0.10),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                size: 20,
                                color:
                                    AppColors.overlay.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text(
                              'Log Food',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color:
                                    AppColors.overlay.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // Meals header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (nutritionStore.entries.isNotEmpty)
                          Text(
                            '${nutritionStore.entries.length} entries',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Food entries
                nutritionStore.entries.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: Center(
                            child: Text(
                              'No meals logged yet',
                              style: AppStyles.mainText().copyWith(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = nutritionStore.entries[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 0, 24, 8),
                              child: Dismissible(
                                key: Key(entry.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color:
                                        Colors.red.withValues(alpha: 0.6),
                                    size: 20,
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
                                        builder: (context) => AddFoodScreen(
                                            existingEntry: entry),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.03),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.name,
                                                style: AppStyles.mainText()
                                                    .copyWith(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                [
                                                  entry.timeFormatted,
                                                  if (entry.protein !=
                                                      null)
                                                    'P:${entry.protein!.toStringAsFixed(0)}g',
                                                  if (entry.carbs != null)
                                                    'C:${entry.carbs!.toStringAsFixed(0)}g',
                                                  if (entry.fats != null)
                                                    'F:${entry.fats!.toStringAsFixed(0)}g',
                                                ].join(' · '),
                                                style: AppStyles.mainText()
                                                    .copyWith(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${entry.calories}',
                                          style:
                                              AppStyles.mainText().copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          ' cal',
                                          style:
                                              AppStyles.mainText().copyWith(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
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
        );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
    );
  }
}

// Calorie ring - thin, white-based
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
                    style: AppStyles.mainHeader().copyWith(
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      color: isOverGoal
                          ? const Color(0xFFFF9500)
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onTargetTap,
                    child: Text(
                      'of $displayTarget cal',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isOverGoal
              ? '${remaining.abs()} cal over'
              : '$remaining remaining',
          style: AppStyles.mainText().copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isOverGoal
                ? const Color(0xFFFF9500)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final bool isOverGoal;

  _CalorieRingPainter({required this.progress, required this.isOverGoal});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final bgPaint = Paint()
      ..color = AppColors.overlay.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = isOverGoal
            ? const Color(0xFFFF9500)
            : AppColors.overlay.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) =>
      old.progress != progress || old.isOverGoal != isOverGoal;
}

// Macro bars - horizontal progress bars instead of rings
class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - current).clamp(0.0, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${current.toStringAsFixed(0)}g',
              style: AppStyles.mainText().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(
                  color: AppColors.overlay.withValues(alpha: 0.06),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${remaining.toStringAsFixed(0)}g left',
          style: AppStyles.mainText().copyWith(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
