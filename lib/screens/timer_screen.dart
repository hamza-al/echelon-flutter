import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../styles.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Duration _duration = const Duration(minutes: 1);
  Duration _remaining = const Duration(minutes: 1);
  Timer? _timer;
  bool _isRunning = false;
  bool _hasStarted = false;

  static const _presetsRow1 = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 1, seconds: 30),
    Duration(minutes: 2),
  ];
  static const _presetsRow2 = [
    Duration(minutes: 3),
    Duration(minutes: 5),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_remaining.inSeconds <= 0) return;
    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        final next = _remaining - const Duration(milliseconds: 100);
        if (next.isNegative || next == Duration.zero) {
          _remaining = Duration.zero;
          _isRunning = false;
          _timer?.cancel();
        } else {
          _remaining = next;
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _duration;
      _isRunning = false;
      _hasStarted = false;
    });
  }

  void _selectPreset(Duration d) {
    _timer?.cancel();
    setState(() {
      _duration = d;
      _remaining = d;
      _isRunning = false;
      _hasStarted = false;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = ((d.inMilliseconds % 1000) ~/ 100).toString();
    if (m > 0) return '$m:$s';
    return '0:$s.$ms';
  }

  String _formatPreset(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (s == 0) return '${m}m';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_duration.inMilliseconds == 0) return 0;
    return 1.0 - (_remaining.inMilliseconds / _duration.inMilliseconds);
  }

  Widget _buildPresetRow(List<Duration> presets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: presets.map((d) {
        final isSelected = _duration == d;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () => _selectPreset(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Text(
                _formatPreset(d),
                style: AppStyles.mainText().copyWith(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _hasStarted && _remaining == Duration.zero;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Timer',
                  style: AppStyles.mainHeader().copyWith(fontSize: 30),
                ),
              ),
              const Spacer(flex: 2),

              // Ring + time
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _RingPainter(progress: _progress, isDone: isDone),
                  child: Center(
                    child: Text(
                      _formatDuration(_remaining),
                      style: AppStyles.mainHeader().copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Presets
              if (!_hasStarted)
                Column(
                  children: [
                    _buildPresetRow(_presetsRow1),
                    const SizedBox(height: 10),
                    _buildPresetRow(_presetsRow2),
                  ],
                ),

              if (_hasStarted) const SizedBox(height: 52),

              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasStarted)
                    GestureDetector(
                      onTap: _reset,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 22,
                        ),
                      ),
                    ),
                  if (_hasStarted) const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () {
                      if (isDone) {
                        _reset();
                      } else if (_isRunning) {
                        _pause();
                      } else {
                        _start();
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        isDone
                            ? Icons.refresh_rounded
                            : _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDone;

  _RingPainter({required this.progress, required this.isDone});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = isDone
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.isDone != isDone;
}
