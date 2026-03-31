import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles.dart';
import '../stores/nutrition_store.dart';
import '../services/calories_api_service.dart';
import '../services/auth_service.dart';
import '../models/food_entry.dart';

class AddFoodScreen extends StatefulWidget {
  final FoodEntry? existingEntry;

  const AddFoodScreen({super.key, this.existingEntry});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _aiFoodController = TextEditingController();
  final _aiFoodFocus = FocusNode();
  bool _aiIsLoading = false;
  String? _aiErrorMessage;

  final _manualNameController = TextEditingController();
  final _manualCaloriesController = TextEditingController();
  final _manualProteinController = TextEditingController();
  final _manualCarbsController = TextEditingController();
  final _manualFatsController = TextEditingController();
  final _manualNameFocus = FocusNode();
  final _manualCaloriesFocus = FocusNode();
  final _manualProteinFocus = FocusNode();
  final _manualCarbsFocus = FocusNode();
  final _manualFatsFocus = FocusNode();
  String? _manualErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _aiErrorMessage = null;
          _manualErrorMessage = null;
        });
        FocusScope.of(context).unfocus();
      }
    });

    if (widget.existingEntry != null) {
      _manualNameController.text = widget.existingEntry!.name;
      _manualCaloriesController.text =
          widget.existingEntry!.calories.toString();
      if (widget.existingEntry!.protein != null) {
        _manualProteinController.text =
            widget.existingEntry!.protein!.toStringAsFixed(1);
      }
      if (widget.existingEntry!.carbs != null) {
        _manualCarbsController.text =
            widget.existingEntry!.carbs!.toStringAsFixed(1);
      }
      if (widget.existingEntry!.fats != null) {
        _manualFatsController.text =
            widget.existingEntry!.fats!.toStringAsFixed(1);
      }
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiFoodController.dispose();
    _aiFoodFocus.dispose();
    _manualNameController.dispose();
    _manualCaloriesController.dispose();
    _manualProteinController.dispose();
    _manualCarbsController.dispose();
    _manualFatsController.dispose();
    _manualNameFocus.dispose();
    _manualCaloriesFocus.dispose();
    _manualProteinFocus.dispose();
    _manualCarbsFocus.dispose();
    _manualFatsFocus.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppStyles.mainText().copyWith(
        fontSize: 15,
        color: AppColors.textMuted,
      ),
      suffixText: suffix,
      suffixStyle: AppStyles.mainText().copyWith(
        fontSize: 13,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.overlay.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.overlay.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.overlay.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.overlay.withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildError(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        message,
        style: AppStyles.mainText().copyWith(
          fontSize: 13,
          color: const Color(0xFFFF6B6B),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: isLoading ? 0.04 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.overlay.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.overlay.withValues(alpha: 0.5),
                  ),
                )
              : Text(
                  label,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.overlay.withValues(alpha: 0.8),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _addFoodWithAI() async {
    final foodItem = _aiFoodController.text.trim();

    if (foodItem.isEmpty) {
      setState(() => _aiErrorMessage = 'Describe what you ate');
      return;
    }

    setState(() {
      _aiIsLoading = true;
      _aiErrorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final caloriesService = CaloriesApiService(authService);
      final response = await caloriesService.getCalories(
        quantity: '1',
        foodItem: foodItem,
      );

      if (mounted) {
        await context.read<NutritionStore>().logFood(
              name: response.itemName,
              calories: response.calories.round(),
              protein: response.macros.protein,
              carbs: response.macros.carbs,
              fats: response.macros.fats,
            );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _aiErrorMessage = 'Failed to get nutrition info. Try again.';
        _aiIsLoading = false;
      });
    }
  }

  Future<void> _addFoodManually() async {
    final name = _manualNameController.text.trim();
    final caloriesText = _manualCaloriesController.text.trim();

    if (name.isEmpty) {
      setState(() => _manualErrorMessage = 'Please enter a food name');
      return;
    }
    if (caloriesText.isEmpty) {
      setState(() => _manualErrorMessage = 'Please enter calories');
      return;
    }

    final calories = int.tryParse(caloriesText);
    if (calories == null || calories < 0) {
      setState(() => _manualErrorMessage = 'Please enter valid calories');
      return;
    }

    double? protein, carbs, fats;

    if (_manualProteinController.text.trim().isNotEmpty) {
      protein = double.tryParse(_manualProteinController.text.trim());
      if (protein == null || protein < 0) {
        setState(() => _manualErrorMessage = 'Invalid protein value');
        return;
      }
    }
    if (_manualCarbsController.text.trim().isNotEmpty) {
      carbs = double.tryParse(_manualCarbsController.text.trim());
      if (carbs == null || carbs < 0) {
        setState(() => _manualErrorMessage = 'Invalid carbs value');
        return;
      }
    }
    if (_manualFatsController.text.trim().isNotEmpty) {
      fats = double.tryParse(_manualFatsController.text.trim());
      if (fats == null || fats < 0) {
        setState(() => _manualErrorMessage = 'Invalid fats value');
        return;
      }
    }

    if (mounted) {
      if (widget.existingEntry != null) {
        await context.read<NutritionStore>().updateFood(
              entryId: widget.existingEntry!.id,
              name: name,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fats: fats,
            );
      } else {
        await context.read<NutritionStore>().logFood(
              name: name,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fats: fats,
            );
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.existingEntry != null ? 'Edit Food' : 'Log Food',
                      style: AppStyles.mainHeader().copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tab bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.overlay.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.overlay.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.overlay.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    labelPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(height: 38, text: 'AI-Powered'),
                      Tab(height: 38, text: 'Manual'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAITab(),
                    _buildManualTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAITab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.overlay.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.overlay.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _aiFoodController,
                focusNode: _aiFoodFocus,
                enabled: !_aiIsLoading,
                style: AppStyles.mainText().copyWith(fontSize: 15, height: 1.5),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: '1 chicken breast\n1 cup rice\n2 eggs scrambled\n...',
                  hintStyle: AppStyles.mainText().copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          _buildError(_aiErrorMessage),
          const SizedBox(height: 16),
          _buildSubmitButton(
            label: 'Log Food',
            onPressed: _addFoodWithAI,
            isLoading: _aiIsLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualNameController,
            focusNode: _manualNameFocus,
            style: AppStyles.mainText().copyWith(fontSize: 15),
            decoration: _fieldDecoration(hint: 'Protein Shake'),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _manualCaloriesFocus.requestFocus(),
          ),
          const SizedBox(height: 20),
          Text(
            'Calories',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualCaloriesController,
            focusNode: _manualCaloriesFocus,
            style: AppStyles.mainText().copyWith(fontSize: 15),
            decoration: _fieldDecoration(hint: '250', suffix: 'cal'),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _manualProteinFocus.requestFocus(),
          ),
          const SizedBox(height: 24),
          Text(
            'Macros',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualProteinController,
                  focusNode: _manualProteinFocus,
                  style: AppStyles.mainText().copyWith(fontSize: 15),
                  decoration: _fieldDecoration(hint: 'P', suffix: 'g'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _manualCarbsFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _manualCarbsController,
                  focusNode: _manualCarbsFocus,
                  style: AppStyles.mainText().copyWith(fontSize: 15),
                  decoration: _fieldDecoration(hint: 'C', suffix: 'g'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _manualFatsFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _manualFatsController,
                  focusNode: _manualFatsFocus,
                  style: AppStyles.mainText().copyWith(fontSize: 15),
                  decoration: _fieldDecoration(hint: 'F', suffix: 'g'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _addFoodManually(),
                ),
              ),
            ],
          ),
          _buildError(_manualErrorMessage),
          const SizedBox(height: 28),
          _buildSubmitButton(
            label: widget.existingEntry != null ? 'Update' : 'Log Food',
            onPressed: _addFoodManually,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
