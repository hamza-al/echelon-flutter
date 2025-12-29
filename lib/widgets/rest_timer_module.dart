import 'dart:async';
import 'package:flutter/material.dart';
import '../styles.dart';

class RestTimerModule extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback? onComplete;

  const RestTimerModule({
    super.key,
    required this.durationSeconds,
    this.onComplete,
  });

  @override
  State<RestTimerModule> createState() => _RestTimerModuleState();
}

class _RestTimerModuleState extends State<RestTimerModule>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    // Pulse animation for the timer
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          widget.onComplete?.call();
        }
      });
    });
  }

  void _skipTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 0;
    });
    widget.onComplete?.call();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remainingSeconds / widget.durationSeconds);
    final isAlmostDone = _remainingSeconds <= 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlmostDone
              ? AppColors.recordingAccent.withOpacity(0.6)
              : AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAlmostDone
                    ? AppColors.recordingAccent
                    : AppColors.primary)
                .withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            'Rest Timer',
            style: AppStyles.questionSubtext().copyWith(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Timer display
          ScaleTransition(
            scale: isAlmostDone ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
            child: Text(
              _formatTime(_remainingSeconds),
              style: AppStyles.secondaryHeader().copyWith(
                fontSize: 48,
                color: isAlmostDone
                    ? AppColors.recordingAccent
                    : AppColors.accent,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.accent.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAlmostDone ? AppColors.recordingAccent : AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Skip button
          TextButton(
            onPressed: _skipTimer,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              'Skip',
              style: AppStyles.questionSubtext().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accent.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

