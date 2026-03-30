import 'package:flutter/material.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  void _loadUserData() {
    final user = UserService.getCurrentUser();
    if (mounted) {
      setState(() {
        _selectedGender = user.gender;
        _selectedGoals = List.from(user.goals);
        _weightLbs = _parseWeight(user.weight);
        _heightInches = _parseHeight(user.height);
      });
    }
  }

  int? _parseWeight(String? raw) {
    if (raw == null) return null;
    // Handle both "170 lbs" (onboarding) and "170" (profile save)
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  int? _parseHeight(String? raw) {
    if (raw == null) return null;
    // Handle "5'8" (onboarding format)
    if (raw.contains("'")) {
      final parts = raw.split("'");
      if (parts.length == 2) {
        final feet = int.tryParse(parts[0].trim()) ?? 0;
        final inches = int.tryParse(parts[1].replaceAll('"', '').trim()) ?? 0;
        return feet * 12 + inches;
      }
    }
    // Handle plain total-inches string like "68" (profile save format)
    return int.tryParse(raw);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = UserService.getCurrentUser();
    user.gender = _selectedGender;
    user.weight = _weightLbs != null ? '$_weightLbs lbs' : null;
    user.height = _heightInches != null
        ? "${_heightInches! ~/ 12}'${_heightInches! % 12}\""
        : null;
    user.goals = _selectedGoals;

    await UserService.saveUser(user);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated',
            style: AppStyles.mainText().copyWith(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showWeightPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int selectedWeight = _weightLbs ?? 150;
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Weight',
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
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
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        childCount: 321,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _weightLbs = selectedWeight);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        int selectedHeight = _heightInches ?? 68;
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Height',
                style: AppStyles.mainText().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
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
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        childCount: 49,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _heightInches = selectedHeight);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profile',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Gender'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildGenderOption('Male')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildGenderOption('Female')),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _sectionLabel('Weight'),
                    const SizedBox(height: 10),
                    _buildPickerField(
                      value: _weightLbs != null ? '$_weightLbs lbs' : null,
                      placeholder: 'Select weight',
                      onTap: _showWeightPicker,
                    ),

                    const SizedBox(height: 20),

                    _sectionLabel('Height'),
                    const SizedBox(height: 10),
                    _buildPickerField(
                      value: _heightInches != null
                          ? '${_heightInches! ~/ 12}\' ${_heightInches! % 12}"'
                          : null,
                      placeholder: 'Select height',
                      onTap: _showHeightPicker,
                    ),

                    const SizedBox(height: 28),

                    _sectionLabel('Goals'),
                    const SizedBox(height: 10),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : Colors.white.withValues(alpha: 0.06),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              goal,
                              style: AppStyles.mainText().copyWith(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.4),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _saveProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Save Changes',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppStyles.mainText().copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildPickerField({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? placeholder,
              style: AppStyles.mainText().copyWith(
                fontSize: 15,
                color: value != null
                    ? AppColors.textPrimary
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
