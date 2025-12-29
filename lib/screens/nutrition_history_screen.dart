import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';
import '../models/daily_nutrition.dart';
import '../styles.dart';
import '../utils/macro_calculator.dart';
import 'package:intl/intl.dart';

class NutritionHistoryScreen extends StatefulWidget {
  const NutritionHistoryScreen({super.key});

  @override
  State<NutritionHistoryScreen> createState() => _NutritionHistoryScreenState();
}

class _NutritionHistoryScreenState extends State<NutritionHistoryScreen> {
  List<DateTime> _historyDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final nutritionService = NutritionService();
    final dates = <DateTime>[];
    
    // Load last 30 days
    for (int i = 1; i <= 30; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final nutrition = await nutritionService.getNutritionForDate(dateKey);
      
      if (nutrition != null && nutrition.entries.isNotEmpty) {
        dates.add(date);
      }
    }
    
    setState(() {
      _historyDates = dates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.chevron_left,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nutrition History',
                    style: AppStyles.mainHeader().copyWith(
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),
            
            // History list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _historyDates.isEmpty
                      ? Center(
                          child: Text(
                            'No history yet',
                            style: AppStyles.mainText().copyWith(
                              color: AppColors.text.withOpacity(0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _historyDates.length,
                          itemBuilder: (context, index) {
                            final date = _historyDates[index];
                            return _HistoryDayCard(date: date);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  final DateTime date;

  const _HistoryDayCard({required this.date});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    
    return DateFormat('EEEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    return FutureBuilder<DailyNutrition?>(
      future: NutritionService().getNutritionForDate(dateKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        
        final nutrition = snapshot.data!;
        final macroTargets = MacroCalculator.calculateTargets();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${nutrition.totalCalories} / ${nutrition.calorieGoal} cal',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      color: AppColors.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Macros row
              Row(
                children: [
                  _MacroChip(
                    label: 'P',
                    value: nutrition.totalProtein.round(),
                    target: macroTargets['protein']?.round() ?? 0,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: 'C',
                    value: nutrition.totalCarbs.round(),
                    target: macroTargets['carbs']?.round() ?? 0,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: 'F',
                    value: nutrition.totalFats.round(),
                    target: macroTargets['fats']?.round() ?? 0,
                    color: const Color(0xFFEC4899),
                  ),
                ],
              ),
              
              // Progress bar
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (nutrition.totalCalories / nutrition.calorieGoal).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    nutrition.isOverGoal ? Colors.red : AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              
              // Meals
              if (nutrition.entries.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...nutrition.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.name,
                        style: AppStyles.mainText().copyWith(
                          fontSize: 13,
                          color: AppColors.text.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${entry.calories} cal',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 13,
                          color: AppColors.text.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value/$target g',
        style: AppStyles.mainText().copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

