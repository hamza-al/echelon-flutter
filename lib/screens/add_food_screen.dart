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

class _AddFoodScreenState extends State<AddFoodScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // AI-powered tab controllers
  final _aiQuantityController = TextEditingController();
  final _aiFoodController = TextEditingController();
  final _aiQuantityFocus = FocusNode();
  final _aiFoodFocus = FocusNode();
  bool _aiIsLoading = false;
  String? _aiErrorMessage;
  
  // Manual tab controllers
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
      // Clear errors when switching tabs
      if (_tabController.indexIsChanging) {
        setState(() {
          _aiErrorMessage = null;
          _manualErrorMessage = null;
        });
        // Dismiss keyboard
        FocusScope.of(context).unfocus();
      }
    });
    
    // If editing, populate the manual tab with existing data
    if (widget.existingEntry != null) {
      _manualNameController.text = widget.existingEntry!.name;
      _manualCaloriesController.text = widget.existingEntry!.calories.toString();
      if (widget.existingEntry!.protein != null) {
        _manualProteinController.text = widget.existingEntry!.protein!.toStringAsFixed(1);
      }
      if (widget.existingEntry!.carbs != null) {
        _manualCarbsController.text = widget.existingEntry!.carbs!.toStringAsFixed(1);
      }
      if (widget.existingEntry!.fats != null) {
        _manualFatsController.text = widget.existingEntry!.fats!.toStringAsFixed(1);
      }
      // Switch to manual tab by default when editing
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiQuantityController.dispose();
    _aiFoodController.dispose();
    _aiQuantityFocus.dispose();
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

  Future<void> _addFoodWithAI() async {
    final quantity = _aiQuantityController.text.trim();
    final foodItem = _aiFoodController.text.trim();
    
    if (foodItem.isEmpty) {
      setState(() {
        _aiErrorMessage = 'Please enter a food item';
      });
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
        quantity: quantity,
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

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _aiErrorMessage = 'Failed to get nutrition info. Please try again.';
        _aiIsLoading = false;
      });
    }
  }

  Future<void> _addFoodManually() async {
    final name = _manualNameController.text.trim();
    final caloriesText = _manualCaloriesController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _manualErrorMessage = 'Please enter a food name';
      });
      return;
    }
    
    if (caloriesText.isEmpty) {
      setState(() {
        _manualErrorMessage = 'Please enter calories';
      });
      return;
    }
    
    final calories = int.tryParse(caloriesText);
    if (calories == null || calories < 0) {
      setState(() {
        _manualErrorMessage = 'Please enter valid calories';
      });
      return;
    }
    
    // Parse optional macros
    double? protein;
    double? carbs;
    double? fats;
    
    if (_manualProteinController.text.trim().isNotEmpty) {
      protein = double.tryParse(_manualProteinController.text.trim());
      if (protein == null || protein < 0) {
        setState(() {
          _manualErrorMessage = 'Please enter valid protein value';
        });
        return;
      }
    }
    
    if (_manualCarbsController.text.trim().isNotEmpty) {
      carbs = double.tryParse(_manualCarbsController.text.trim());
      if (carbs == null || carbs < 0) {
        setState(() {
          _manualErrorMessage = 'Please enter valid carbs value';
        });
        return;
      }
    }
    
    if (_manualFatsController.text.trim().isNotEmpty) {
      fats = double.tryParse(_manualFatsController.text.trim());
      if (fats == null || fats < 0) {
        setState(() {
          _manualErrorMessage = 'Please enter valid fats value';
        });
        return;
      }
    }

    if (mounted) {
      // Check if we're editing or adding
      if (widget.existingEntry != null) {
        // Update existing entry
        await context.read<NutritionStore>().updateFood(
          entryId: widget.existingEntry!.id,
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
        );
      } else {
        // Add new entry
        await context.read<NutritionStore>().logFood(
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingEntry != null ? 'Edit Food' : 'Log Food',
                            style: AppStyles.mainHeader().copyWith(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.existingEntry != null ? 'Update your meal' : 'Track your nutrition',
                            style: AppStyles.questionSubtext().copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: AppColors.background,
                    unselectedLabelColor: AppColors.accent.withOpacity(0.5),
                    labelStyle: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    labelPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 16),
                            SizedBox(width: 6),
                            Text('AI-Powered'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 6),
                            Text('Manual'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAIPoweredTab(),
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

  Widget _buildAIPoweredTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Describe your food naturally and we\'ll calculate the nutrition for you',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      color: AppColors.accent.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Quantity Field
          Text(
            'Quantity (Optional)',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aiQuantityController,
            focusNode: _aiQuantityFocus,
            enabled: !_aiIsLoading,
            style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'e.g., 2, 1 cup, 100g',
              hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _aiFoodFocus.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // Food Item Field
          Text(
            'Food Item',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aiFoodController,
            focusNode: _aiFoodFocus,
            enabled: !_aiIsLoading,
            style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'e.g., grilled chicken breast',
              hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _addFoodWithAI(),
          ),
          
          if (_aiErrorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _aiErrorMessage!,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Add Button
          ElevatedButton(
            onPressed: _aiIsLoading ? null : _addFoodWithAI,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.5),
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _aiIsLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Log Food',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                    ),
                  ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enter nutrition values manually for precise tracking',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 13,
                      color: AppColors.accent.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Food Name Field
          Text(
            'Food Name',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
                    TextField(
                      controller: _manualNameController,
                      focusNode: _manualNameFocus,
                      style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'e.g., Protein Shake',
              hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _manualCaloriesFocus.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // Calories Field
          Text(
            'Calories',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualCaloriesController,
            focusNode: _manualCaloriesFocus,
            style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'e.g., 250',
              hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixText: 'cal',
              suffixStyle: AppStyles.mainText().copyWith(
                fontSize: 14,
                color: AppColors.accent.withOpacity(0.5),
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _manualProteinFocus.requestFocus(),
          ),
          
          const SizedBox(height: 32),
          
          // Macros Section Header
          Text(
            'Macros (Optional)',
            style: AppStyles.mainText().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Macros Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protein',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualProteinController,
                      focusNode: _manualProteinFocus,
                      style: AppStyles.mainText().copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixText: 'g',
                        suffixStyle: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onSubmitted: (_) => _manualCarbsFocus.requestFocus(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carbs',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualCarbsController,
                      focusNode: _manualCarbsFocus,
                      style: AppStyles.mainText().copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixText: 'g',
                        suffixStyle: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onSubmitted: (_) => _manualFatsFocus.requestFocus(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fats',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualFatsController,
                      focusNode: _manualFatsFocus,
                      style: AppStyles.mainText().copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixText: 'g',
                        suffixStyle: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onSubmitted: (_) => _addFoodManually(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_manualErrorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _manualErrorMessage!,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Add Button
          ElevatedButton(
            onPressed: _addFoodManually,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.existingEntry != null ? 'Update Food' : 'Log Food',
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.background,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

