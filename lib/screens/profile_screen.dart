import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedGender;
  List<String> _selectedGoals = [];
  int? _weightLbs;
  int? _heightInches;

  final List<String> _availableGoals = [
    'Lose Weight',
    'Build Muscle',
    'Get Stronger',
    'Improve Endurance',
    'Stay Active',
    'General Fitness',
  ];

  @override
  void initState() {
    super.initState();
    // Load immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload whenever screen is shown
    _loadUserData();
  }

  void _loadUserData() {
    final user = UserService.getCurrentUser();
    if (mounted) {
      setState(() {
        _selectedGender = user.gender;
        _selectedGoals = List.from(user.goals);
        _weightLbs = user.weight != null ? int.tryParse(user.weight!) : null;
        _heightInches = user.height != null ? int.tryParse(user.height!) : null;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = UserService.getCurrentUser();
    user.gender = _selectedGender;
    user.weight = _weightLbs?.toString();
    user.height = _heightInches?.toString();
    user.goals = _selectedGoals;

    await UserService.saveUser(user);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated!',
            style: AppStyles.mainText(),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showWeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int selectedWeight = _weightLbs ?? 150;
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Select Weight',
                style: AppStyles.mainText().copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight bar
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        selectedWeight = index + 80;
                      },
                      controller: FixedExtentScrollController(
                        initialItem: (_weightLbs ?? 150) - 80,
                      ),
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final weight = index + 80;
                          return Center(
                            child: Text(
                              '$weight lbs',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        childCount: 321, // 80 to 400 lbs
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _weightLbs = selectedWeight;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int selectedHeight = _heightInches ?? 68;
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Select Height',
                style: AppStyles.mainText().copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight bar
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        selectedHeight = index + 48;
                      },
                      controller: FixedExtentScrollController(
                        initialItem: (_heightInches ?? 68) - 48,
                      ),
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final inches = index + 48;
                          final feet = inches ~/ 12;
                          final remainingInches = inches % 12;
                          return Center(
                            child: Text(
                              '$feet\' $remainingInches"',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        childCount: 49, // 48 to 96 inches (4' to 8')
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _heightInches = selectedHeight;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                    ),
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: AppStyles.mainHeader().copyWith(
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your information',
                          style: AppStyles.questionSubtext(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gender Selection
                    Text(
                      'Gender',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGenderOption('Male'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGenderOption('Female'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Weight
                    Text(
                      'Weight',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showWeightPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _weightLbs != null
                                  ? '$_weightLbs lbs'
                                  : 'Select weight',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 16,
                                color: _weightLbs != null
                                    ? AppColors.accent
                                    : AppColors.accent.withOpacity(0.5),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.accent.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Height
                    Text(
                      'Height',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showHeightPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _heightInches != null
                                  ? '${_heightInches! ~/ 12}\' ${_heightInches! % 12}"'
                                  : 'Select height',
                              style: AppStyles.mainText().copyWith(
                                fontSize: 16,
                                color: _heightInches != null
                                    ? AppColors.accent
                                    : AppColors.accent.withOpacity(0.5),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.accent.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Goals
                    Text(
                      'Fitness Goals',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableGoals.map((goal) {
                        final isSelected = _selectedGoals.contains(goal);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGoals.remove(goal);
                              } else {
                                _selectedGoals.add(goal);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              goal,
                              style: AppStyles.mainText().copyWith(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.accent.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Changes',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: AppStyles.mainText().copyWith(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.accent : AppColors.accent.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

