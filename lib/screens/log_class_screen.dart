import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/class_entry.dart';
import '../services/class_service.dart';

class LogClassScreen extends StatefulWidget {
  final ClassEntry? existingEntry;

  const LogClassScreen({super.key, this.existingEntry});

  @override
  State<LogClassScreen> createState() => _LogClassScreenState();
}

class _LogClassScreenState extends State<LogClassScreen> {
  String? _selectedClass;
  int? _selectedDuration;
  int? _selectedIntensity;
  final _customNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _notesFocus = FocusNode();
  bool _showCustomField = false;

  static const List<_ClassOption> _classOptions = [
    _ClassOption('Pilates', Icons.self_improvement),
    _ClassOption('Orange Theory', Icons.monitor_heart),
    _ClassOption('Yoga', Icons.spa),
    _ClassOption('Spin', Icons.pedal_bike),
    _ClassOption('Boxing', Icons.sports_mma),
    _ClassOption('HIIT', Icons.bolt),
    _ClassOption('Swimming', Icons.pool),
    _ClassOption('CrossFit', Icons.fitness_center),
    _ClassOption('Dance', Icons.music_note),
    _ClassOption('Martial Arts', Icons.sports_martial_arts),
    _ClassOption('Running', Icons.directions_run),
    _ClassOption('Other', Icons.add),
  ];

  static const List<int> _durationPresets = [15, 30, 45, 60, 75, 90, 120];

  static const List<String> _intensityLabels = [
    'Light',
    'Moderate',
    'Hard',
    'Intense',
    'Max',
  ];

  static const Map<String, double> _calPerMin = {
    'Pilates': 5,
    'Orange Theory': 9,
    'Yoga': 4,
    'Spin': 9,
    'Boxing': 9,
    'HIIT': 10,
    'Swimming': 8,
    'CrossFit': 10,
    'Dance': 7,
    'Martial Arts': 9,
    'Running': 9,
    'Other': 7,
  };

  static const List<double> _intensityMultipliers = [
    0.8,
    1.0,
    1.2,
    1.35,
    1.5,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      final isPreset =
          _classOptions.any((o) => o.name == entry.className && o.name != 'Other');
      if (isPreset) {
        _selectedClass = entry.className;
      } else {
        _selectedClass = 'Other';
        _showCustomField = true;
        _customNameController.text = entry.className;
      }
      _selectedDuration = entry.durationMinutes;
      _selectedIntensity = entry.intensity;
      if (entry.notes != null) {
        _notesController.text = entry.notes!;
      }
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _notesController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  String get _resolvedClassName {
    if (_selectedClass == 'Other') {
      return _customNameController.text.trim();
    }
    return _selectedClass ?? '';
  }

  bool get _canSave {
    if (_selectedClass == null) return false;
    if (_selectedClass == 'Other' && _customNameController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  int? get _estimatedCalories {
    if (_selectedClass == null || _selectedDuration == null || _selectedIntensity == null) {
      return null;
    }
    final baseName = _selectedClass == 'Other' ? 'Other' : _selectedClass!;
    final rate = _calPerMin[baseName] ?? 7;
    final multiplier = _intensityMultipliers[_selectedIntensity! - 1];
    return (rate * _selectedDuration! * multiplier).round();
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final className = _resolvedClassName;
    final notes =
        _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final cals = _estimatedCalories;

    if (widget.existingEntry != null) {
      final updated = ClassEntry(
        id: widget.existingEntry!.id,
        className: className,
        durationMinutes: _selectedDuration,
        notes: notes,
        intensity: _selectedIntensity,
        caloriesBurned: cals,
        timestamp: widget.existingEntry!.timestamp,
      );
      await ClassService.updateClass(updated);
    } else {
      final entry = ClassEntry(
        className: className,
        durationMinutes: _selectedDuration,
        notes: notes,
        intensity: _selectedIntensity,
        caloriesBurned: cals,
      );
      await ClassService.logClass(entry);
    }

    if (mounted) {
      final isEdit = widget.existingEntry != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Class updated' : '$className logged',
            style: AppStyles.mainText().copyWith(fontSize: 14),
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColors.overlay.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEditing ? 'Edit Class' : 'Log a Class',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('What did you do?'),
                      const SizedBox(height: 12),
                      _buildClassGrid(),

                      if (_showCustomField) ...[
                        const SizedBox(height: 14),
                        _buildGlassField(
                          controller: _customNameController,
                          hint: 'Class name',
                          capitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],

                      const SizedBox(height: 28),
                      _sectionLabel('Duration'),
                      const SizedBox(height: 12),
                      _buildDurationRow(),

                      const SizedBox(height: 28),
                      _sectionLabel('Intensity'),
                      const SizedBox(height: 12),
                      _buildIntensityRow(),

                      if (_estimatedCalories != null) ...[
                        const SizedBox(height: 16),
                        _buildCalorieReadout(),
                      ],

                      const SizedBox(height: 28),
                      _sectionLabel('Notes'),
                      const SizedBox(height: 12),
                      _buildGlassField(
                        controller: _notesController,
                        focusNode: _notesFocus,
                        hint: 'How was the class?',
                        maxLines: 3,
                        capitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 32),
                      _buildSaveButton(isEditing),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        color: AppColors.overlay.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildClassGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: _classOptions.map((option) {
        final isSelected = _selectedClass == option.name;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedClass = option.name;
              _showCustomField = option.name == 'Other';
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.overlay.withValues(alpha: 0.10)
                  : AppColors.overlay.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.overlay.withValues(alpha: 0.20)
                    : AppColors.overlay.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option.icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.overlay.withValues(alpha: 0.85)
                      : AppColors.overlay.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 6),
                Text(
                  option.name,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.overlay.withValues(alpha: 0.85)
                        : AppColors.overlay.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _durationPresets.map((mins) {
        final isSelected = _selectedDuration == mins;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDuration = _selectedDuration == mins ? null : mins;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.overlay.withValues(alpha: 0.12)
                  : AppColors.overlay.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.overlay.withValues(alpha: 0.22)
                    : AppColors.overlay.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Text(
              '${mins}m',
              style: AppStyles.mainText().copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.overlay.withValues(alpha: 0.85)
                    : AppColors.overlay.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntensityRow() {
    return Row(
      children: List.generate(_intensityLabels.length, (i) {
        final level = i + 1;
        final isSelected = _selectedIntensity == level;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _intensityLabels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIntensity = _selectedIntensity == level ? null : level;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.overlay.withValues(alpha: 0.12)
                      : AppColors.overlay.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.overlay.withValues(alpha: 0.22)
                        : AppColors.overlay.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _intensityLabels[i],
                    style: AppStyles.mainText().copyWith(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.overlay.withValues(alpha: 0.85)
                          : AppColors.overlay.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalorieReadout() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.overlay.withValues(alpha: 0.04),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '~${_estimatedCalories}',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.overlay.withValues(alpha: 0.7),
                  ),
                ),
                TextSpan(
                  text: ' cal',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.overlay.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: AppStyles.mainText().copyWith(fontSize: 15),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppStyles.mainText().copyWith(
          fontSize: 15,
          color: AppColors.overlay.withValues(alpha: 0.15),
        ),
        filled: true,
        fillColor: AppColors.overlay.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.overlay.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.overlay.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.overlay.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      child: AnimatedOpacity(
        opacity: _canSave ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.overlay.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.overlay.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              isEditing ? 'Update Class' : 'Log Class',
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.overlay.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassOption {
  final String name;
  final IconData icon;

  const _ClassOption(this.name, this.icon);
}
