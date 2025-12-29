import 'package:flutter/material.dart';
import '../../styles.dart';

class HeightInputStep extends StatefulWidget {
  final String? initialHeight;
  final Function(String) onHeightEntered;

  const HeightInputStep({
    super.key,
    this.initialHeight,
    required this.onHeightEntered,
  });

  @override
  State<HeightInputStep> createState() => _HeightInputStepState();
}

class _HeightInputStepState extends State<HeightInputStep> {
  late TextEditingController _feetController;
  late TextEditingController _inchesController;
  String _unit = 'ft/in';

  @override
  void initState() {
    super.initState();
    if (widget.initialHeight != null && widget.initialHeight!.contains("'")) {
      final parts = widget.initialHeight!.split("'");
      if (parts.length == 2) {
        _feetController = TextEditingController(text: parts[0]);
        _inchesController = TextEditingController(
            text: parts[1].replaceAll('"', '').trim());
      } else {
        _feetController = TextEditingController();
        _inchesController = TextEditingController();
      }
    } else {
      _feetController = TextEditingController();
      _inchesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _updateHeight() {
    if (_feetController.text.isNotEmpty || _inchesController.text.isNotEmpty) {
      if (_unit == 'ft/in') {
        final feet = _feetController.text.isEmpty ? '0' : _feetController.text;
        final inches = _inchesController.text.isEmpty ? '0' : _inchesController.text;
        widget.onHeightEntered("$feet'$inches\"");
      } else {
        final cm = _inchesController.text.isEmpty ? '0' : _inchesController.text;
        widget.onHeightEntered('$cm cm');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'What\'s your height?',
          style: AppStyles.mainHeader(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _unit == 'ft/in'
              ? [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _feetController,
                      keyboardType: TextInputType.number,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppStyles.mainText().copyWith(
                          fontSize: 32,
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => _updateHeight(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'ft',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _inchesController,
                      keyboardType: TextInputType.number,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppStyles.mainText().copyWith(
                          fontSize: 32,
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => _updateHeight(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'in',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ]
              : [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _inchesController,
                      keyboardType: TextInputType.number,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppStyles.mainText().copyWith(
                          fontSize: 32,
                          color: AppColors.accent.withOpacity(0.3),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => _updateHeight(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'cm',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            setState(() {
              _unit = _unit == 'ft/in' ? 'cm' : 'ft/in';
              _feetController.clear();
              _inchesController.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Switch to ${_unit == 'ft/in' ? 'cm' : 'ft/in'}',
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

