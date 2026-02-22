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

  static const List<int> _durationPresets = [30, 45, 60, 75, 90];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      final isPreset = _classOptions.any((o) => o.name == entry.className && o.name != 'Other');
      if (isPreset) {
        _selectedClass = entry.className;
      } else {
        _selectedClass = 'Other';
        _showCustomField = true;
        _customNameController.text = entry.className;
      }
      _selectedDuration = entry.durationMinutes;
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
    if (_selectedClass == 'Other' && _customNameController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final className = _resolvedClassName;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    if (widget.existingEntry != null) {
      final updated = ClassEntry(
        id: widget.existingEntry!.id,
        className: className,
        durationMinutes: _selectedDuration,
        notes: notes,
        timestamp: widget.existingEntry!.timestamp,
      );
      await ClassService.updateClass(updated);
    } else {
      final entry = ClassEntry(
        className: className,
        durationMinutes: _selectedDuration,
        notes: notes,
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
          backgroundColor: AppColors.cardBackground,
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
                            isEditing ? 'Edit Class' : 'Log a Class',
                            style: AppStyles.mainHeader().copyWith(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing ? 'Update your activity' : 'Track your activity',
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

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class type label
                      Text(
                        'What did you do?',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Class type grid
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: _classOptions.map((option) {
                          final isSelected = _selectedClass == option.name;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedClass = option.name;
                                _showCustomField = option.name == 'Other';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight.withOpacity(0.15)
                                    : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : Colors.white.withOpacity(0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 24,
                                    color: isSelected
                                        ? AppColors.primaryLight
                                        : AppColors.accent.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    option.name,
                                    style: AppStyles.mainText().copyWith(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primaryLight
                                          : AppColors.accent.withOpacity(0.8),
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
                      ),

                      // Custom name field
                      if (_showCustomField) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _customNameController,
                          style: AppStyles.mainText().copyWith(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Class name',
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Duration
                      Text(
                        'Duration (Optional)',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: _durationPresets.map((mins) {
                          final isSelected = _selectedDuration == mins;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: mins == _durationPresets.last ? 0 : 8,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDuration =
                                        _selectedDuration == mins ? null : mins;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryLight.withOpacity(0.15)
                                        : AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryLight
                                          : Colors.white.withOpacity(0.1),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${mins}m',
                                      style: AppStyles.mainText().copyWith(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : AppColors.accent.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Notes
                      Text(
                        'Notes (Optional)',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _notesController,
                        focusNode: _notesFocus,
                        style: AppStyles.mainText().copyWith(fontSize: 16),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'How was the class?',
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
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canSave ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            disabledBackgroundColor:
                                AppColors.primaryLight.withOpacity(0.3),
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'Update Class' : 'Log Class',
                            style: AppStyles.mainText().copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _canSave
                                  ? AppColors.background
                                  : AppColors.background.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
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
}

class _ClassOption {
  final String name;
  final IconData icon;

  const _ClassOption(this.name, this.icon);
}
