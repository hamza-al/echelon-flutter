import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../styles.dart';
import '../stores/active_workout_store.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Standalone timer state (used only when no workout is active)
  Duration _standaloneDuration = const Duration(minutes: 1);
  Duration _standaloneRemaining = const Duration(minutes: 1);
  Timer? _standaloneTimer;
  bool _standaloneRunning = false;
  bool _standaloneStarted = false;

  // Elapsed ticker for workout banner
  Timer? _elapsedTicker;

  static const _presets = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 1, seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 3),
    Duration(minutes: 5),
  ];

  @override
  void dispose() {
    _standaloneTimer?.cancel();
    _elapsedTicker?.cancel();
    super.dispose();
  }

  // --- Standalone timer controls ---

  void _saStart() {
    if (_standaloneRemaining.inSeconds <= 0) return;
    setState(() {
      _standaloneRunning = true;
      _standaloneStarted = true;
    });
    _standaloneTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        final next = _standaloneRemaining - const Duration(milliseconds: 100);
        if (next.isNegative || next == Duration.zero) {
          _standaloneRemaining = Duration.zero;
          _standaloneRunning = false;
          _standaloneTimer?.cancel();
        } else {
          _standaloneRemaining = next;
        }
      });
    });
  }

  void _saPause() {
    _standaloneTimer?.cancel();
    setState(() => _standaloneRunning = false);
  }

  void _saReset() {
    _standaloneTimer?.cancel();
    setState(() {
      _standaloneRemaining = _standaloneDuration;
      _standaloneRunning = false;
      _standaloneStarted = false;
    });
  }

  void _saSelectPreset(Duration d) {
    _standaloneTimer?.cancel();
    setState(() {
      _standaloneDuration = d;
      _standaloneRemaining = d;
      _standaloneRunning = false;
      _standaloneStarted = false;
    });
  }

  double get _saProgress {
    if (_standaloneDuration.inMilliseconds == 0) return 0;
    return 1.0 - (_standaloneRemaining.inMilliseconds / _standaloneDuration.inMilliseconds);
  }

  // --- Formatting ---

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = ((d.inMilliseconds % 1000) ~/ 100).toString();
    if (m > 0) return '$m:$s';
    return '0:$s.$ms';
  }

  String _fmtPreset(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (s == 0) return '${m}m';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _fmtSeconds(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveWorkoutStore>(
      builder: (context, store, _) {
        final inWorkout = store.hasActiveWorkout;
        final hasSharedRest = store.hasActiveRest;

        if (inWorkout && hasSharedRest) {
          _ensureElapsedTicker();
          return _buildWorkoutRest(store);
        }

        _stopElapsedTicker();

        if (inWorkout) {
          return _buildWorkoutIdle(store);
        }

        return _buildStandalone();
      },
    );
  }

  void _ensureElapsedTicker() {
    _elapsedTicker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  void _stopElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
  }

  // --- Workout rest view (timer running from voice/workout) ---

  Widget _buildWorkoutRest(ActiveWorkoutStore store) {
    final remaining = store.restRemaining;
    final progress = store.restProgress;
    final isAlmostDone = remaining <= 5 && remaining > 0;
    final isDone = remaining == 0 && !store.restRunning;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            children: [
              _workoutBanner(store),
              const Spacer(flex: 2),

              // REST label
              Text(
                isDone ? 'REST COMPLETE' : 'RESTING',
                style: AppStyles.mainText().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isDone
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    isDone: isDone,
                    isAlmostDone: isAlmostDone,
                  ),
                  child: Center(
                    child: Text(
                      _fmtSeconds(remaining),
                      style: AppStyles.mainHeader().copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1,
                        color: isAlmostDone
                            ? const Color(0xFFFF6B6B)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              if (!isDone)
                GestureDetector(
                  onTap: store.skipRest,
                  child: Text(
                    'Skip',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // --- Workout idle (workout active but no rest timer) ---

  Widget _buildWorkoutIdle(ActiveWorkoutStore store) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            children: [
              _workoutBanner(store),
              const Spacer(flex: 2),

              Text(
                'REST TIMER',
                style: AppStyles.mainText().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _RingPainter(progress: 0, isDone: false),
                  child: Center(
                    child: Text(
                      '0:00',
                      style: AppStyles.mainHeader().copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Quick-start presets
              Text(
                'Quick start',
                style: AppStyles.mainText().copyWith(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 12),
              _presetChipRow(store),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChipRow(ActiveWorkoutStore store) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _presets.map((d) {
        return GestureDetector(
          onTap: () => store.startRest(d.inSeconds),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Text(
              _fmtPreset(d),
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Standalone (no workout) ---

  Widget _buildStandalone() {
    final isDone = _standaloneStarted && _standaloneRemaining == Duration.zero;

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

              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _RingPainter(progress: _saProgress, isDone: isDone),
                  child: Center(
                    child: Text(
                      _fmtDuration(_standaloneRemaining),
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

              if (!_standaloneStarted)
                Column(
                  children: [
                    _buildPresetRow(_presets.sublist(0, 4)),
                    const SizedBox(height: 10),
                    _buildPresetRow(_presets.sublist(4)),
                  ],
                ),
              if (_standaloneStarted) const SizedBox(height: 52),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_standaloneStarted)
                    _circleButton(Icons.refresh_rounded, _saReset, small: true),
                  if (_standaloneStarted) const SizedBox(width: 24),
                  _circleButton(
                    isDone
                        ? Icons.refresh_rounded
                        : _standaloneRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    () {
                      if (isDone) {
                        _saReset();
                      } else if (_standaloneRunning) {
                        _saPause();
                      } else {
                        _saStart();
                      }
                    },
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

  // --- Shared widgets ---

  Widget _workoutBanner(ActiveWorkoutStore store) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: store.restRunning
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.workoutLabel ?? 'Workout',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.workoutElapsed} · ${store.setsLogged} sets',
                  style: AppStyles.mainText().copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'ACTIVE',
            style: AppStyles.mainText().copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetRow(List<Duration> presets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: presets.map((d) {
        final isSelected = _standaloneDuration == d;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () => _saSelectPreset(d),
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
                _fmtPreset(d),
                style: AppStyles.mainText().copyWith(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {bool small = false}) {
    final size = small ? 52.0 : 64.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: small ? 0.06 : 0.10),
          border: Border.all(
            color: Colors.white.withValues(alpha: small ? 0.10 : 0.15),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: small ? 0.6 : 1.0),
          size: small ? 22.0 : 28.0,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDone;
  final bool isAlmostDone;

  _RingPainter({
    required this.progress,
    required this.isDone,
    this.isAlmostDone = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = isAlmostDone
            ? const Color(0xFFFF6B6B).withValues(alpha: 0.8)
            : isDone
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
      old.progress != progress ||
      old.isDone != isDone ||
      old.isAlmostDone != isAlmostDone;
}
