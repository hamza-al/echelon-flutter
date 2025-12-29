import 'package:flutter/material.dart';
import '../../styles.dart';

class WeightInputStep extends StatefulWidget {
  final String? initialWeight;
  final Function(String) onWeightEntered;

  const WeightInputStep({
    super.key,
    this.initialWeight,
    required this.onWeightEntered,
  });

  @override
  State<WeightInputStep> createState() => _WeightInputStepState();
}

class _WeightInputStepState extends State<WeightInputStep> {
  late TextEditingController _controller;
  String _unit = 'lbs';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialWeight);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'What\'s your weight?',
          style: AppStyles.mainHeader(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: _controller,
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
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    widget.onWeightEntered('$value $_unit');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _unit = _unit == 'lbs' ? 'kg' : 'lbs';
                  if (_controller.text.isNotEmpty) {
                    widget.onWeightEntered('${_controller.text} $_unit');
                  }
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
                  _unit,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

