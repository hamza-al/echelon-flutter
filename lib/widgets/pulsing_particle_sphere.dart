import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PulsingParticleSphere extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color highlightColor;

  const PulsingParticleSphere({
    super.key,
    this.size = 120,
    this.primaryColor = const Color(0xFF7C3AED),
    this.secondaryColor = const Color(0xFFA78BFA),
    this.accentColor = const Color(0xFF6D28D9),
    this.highlightColor = const Color(0xFF8B5CF6),
  });

  @override
  State<PulsingParticleSphere> createState() => _PulsingParticleSphereState();
}

class _PulsingParticleSphereState extends State<PulsingParticleSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  late Float32List _grainPoints;

  static const int _grainCount = 500;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _controller.addListener(_tick);
    _buildGrain();
  }

  void _buildGrain() {
    _grainPoints = Float32List(_grainCount * 2);
    final rng = math.Random(42);
    for (int i = 0; i < _grainCount; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final d = math.sqrt(rng.nextDouble());
      _grainPoints[i * 2] = math.cos(a) * d;
      _grainPoints[i * 2 + 1] = math.sin(a) * d;
    }
  }

  void _tick() {
    setState(() {
      _time += 1.0 / 60.0;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _AuroraPainter(
          time: _time,
          orbSize: widget.size,
          colors: [
            widget.primaryColor,
            widget.secondaryColor,
            widget.accentColor,
            widget.highlightColor,
          ],
          grainPoints: _grainPoints,
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double time;
  final double orbSize;
  final List<Color> colors;
  final Float32List grainPoints;

  _AuroraPainter({
    required this.time,
    required this.orbSize,
    required this.colors,
    required this.grainPoints,
  });

  static const _layers = <List<double>>[
    [0.0, 0.90, 0.04, 0.0],
    [1.0, 0.88, 0.04, 2.1],
    [2.0, 0.89, 0.04, 4.2],
    [3.0, 0.85, 0.03, 6.0],
    [-1.0, 0.80, 0.02, 1.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = orbSize * 0.48;

    _paintOuterGlow(canvas, cx, cy, maxR);

    for (final cfg in _layers) {
      _paintLayer(canvas, cx, cy, maxR, cfg);
    }

    _paintCenterLight(canvas, cx, cy, maxR);
    _paintGrain(canvas, cx, cy, maxR);
  }

  void _paintOuterGlow(Canvas canvas, double cx, double cy, double maxR) {
    final pulse = 1.0 + math.sin(time * 0.8) * 0.04;
    final glowR = maxR * 1.6 * pulse;

    final blueGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[0].withValues(alpha: 0.25),
          colors[0].withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(cx - maxR * 0.08, cy), radius: glowR));
    canvas.drawCircle(Offset(cx - maxR * 0.08, cy), glowR, blueGlow);

    final pinkGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.20),
          colors[1].withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(cx + maxR * 0.08, cy + maxR * 0.05),
          radius: glowR * 0.9));
    canvas.drawCircle(
        Offset(cx + maxR * 0.08, cy + maxR * 0.05), glowR * 0.9, pinkGlow);

    final lavGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[2].withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: glowR * 0.7));
    canvas.drawCircle(Offset(cx, cy), glowR * 0.7, lavGlow);
  }

  void _paintLayer(
      Canvas canvas, double cx, double cy, double maxR, List<double> cfg) {
    final colorIdx = cfg[0].toInt();
    final radiusFactor = cfg[1];
    final driftScale = cfg[2];
    final phase = cfg[3];

    final pulse =
        1.0 + math.sin(time * (0.8 + colorIdx * 0.15) + phase) * 0.05;
    final layerR = maxR * radiusFactor * pulse;

    final dx = math.sin(time * 0.4 + phase) * maxR * driftScale;
    final dy = math.cos(time * 0.5 + phase * 0.7) * maxR * driftScale;

    final path = Path();
    const seg = 180;

    for (int j = 0; j <= seg; j++) {
      final a = (j / seg) * math.pi * 2;

      final w1 = math.sin(a * 2 + time * 0.6 + phase) * 0.07;
      final w2 = math.sin(a * 3 - time * 0.45 + phase * 1.2) * 0.04;
      final w3 = math.sin(a * 5 + time * 0.3 + phase * 0.5) * 0.015;

      final r = layerR * (1.0 + w1 + w2 + w3);
      final x = cx + dx + r * math.cos(a);
      final y = cy + dy + r * math.sin(a);

      if (j == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final color = colorIdx < 0
        ? const Color(0xFFF5F3F8)
        : colors[colorIdx % colors.length];

    final paint = Paint()
      ..color = colorIdx < 0 ? color : color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _paintCenterLight(Canvas canvas, double cx, double cy, double maxR) {
    final pulse = 1.0 + math.sin(time * 1.0) * 0.08;
    final r = maxR * 0.4 * pulse;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  void _paintGrain(Canvas canvas, double cx, double cy, double maxR) {
    final scaled = Float32List(grainPoints.length);
    for (int i = 0; i < grainPoints.length ~/ 2; i++) {
      scaled[i * 2] = cx + grainPoints[i * 2] * maxR;
      scaled[i * 2 + 1] = cy + grainPoints[i * 2 + 1] * maxR;
    }

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawRawPoints(ui.PointMode.points, scaled, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.time != time;
}
