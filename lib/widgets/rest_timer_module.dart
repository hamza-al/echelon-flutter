import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../styles.dart';

class RestTimerModule extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback? onComplete;
  final bool useExternalCountdown;

  const RestTimerModule({
    super.key,
    required this.durationSeconds,
    this.onComplete,
    this.useExternalCountdown = false,
  });

  @override
  State<RestTimerModule> createState() => _RestTimerModuleState();
}

class _RestTimerModuleState extends State<RestTimerModule>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  AnimationController? _progressController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    if (!widget.useExternalCountdown) {
      _progressController = AnimationController(
        duration: Duration(seconds: widget.durationSeconds),
        vsync: this,
      )..forward();
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(RestTimerModule old) {
    super.didUpdateWidget(old);
    if (widget.useExternalCountdown) {
      _remainingSeconds = widget.durationSeconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController?.dispose();
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
    final remaining = widget.useExternalCountdown
        ? widget.durationSeconds
        : _remainingSeconds;
    final isAlmostDone = remaining <= 5 && remaining > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'REST',
          style: AppStyles.mainText().copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.overlay.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: 100,
          height: 100,
          child: widget.useExternalCountdown
              ? CustomPaint(
                  painter: _RingPainter(progress: 0, isAlmostDone: isAlmostDone),
                  child: Center(
                    child: Text(
                      _formatTime(remaining),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isAlmostDone
                            ? const Color(0xFFFF6B6B)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
              : AnimatedBuilder2(
                  listenable: _progressController!,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RingPainter(
                        progress: _progressController!.value,
                        isAlmostDone: isAlmostDone,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Text(
                      _formatTime(remaining),
                      style: AppStyles.mainText().copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isAlmostDone
                            ? const Color(0xFFFF6B6B)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 14),

        GestureDetector(
          onTap: _skipTimer,
          child: Text(
            'Skip',
            style: AppStyles.mainText().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.overlay.withValues(alpha: 0.25),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isAlmostDone;

  _RingPainter({required this.progress, required this.isAlmostDone});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 3.0;

    final bgPaint = Paint()
      ..color = AppColors.overlay.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = isAlmostDone
          ? const Color(0xFFFF6B6B).withValues(alpha: 0.8)
          : AppColors.overlay.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isAlmostDone != isAlmostDone;
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
