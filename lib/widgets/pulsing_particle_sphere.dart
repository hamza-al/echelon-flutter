import 'dart:math' as math;
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
    this.primaryColor = const Color(0xFF6355FF),
    this.secondaryColor = const Color(0xFF5040FF),
    this.accentColor = const Color(0xFFA78BFA),
    this.highlightColor = const Color(0xFFC4B5FD),
  });

  @override
  State<PulsingParticleSphere> createState() => _PulsingParticleSphereState();
}

class _PulsingParticleSphereState extends State<PulsingParticleSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  double _time = 0;

  static const int _particleCount = 180;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat();

    _particles = _generateParticles();
    _controller.addListener(_updateAnimation);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateAnimation);
    _controller.dispose();
    super.dispose();
  }

  void _updateAnimation() {
    setState(() {
      _time = _controller.value * math.pi * 2;
    });
  }

  List<Particle> _generateParticles() {
    final particles = <Particle>[];
    final goldenAngle = math.pi * (3 - math.sqrt(5));

    for (int i = 0; i < _particleCount; i++) {
      final y = 1 - (i / (_particleCount - 1)) * 2;
      final theta = goldenAngle * i;
      final phi = math.acos(y.clamp(-1.0, 1.0));

      particles.add(Particle(
        baseTheta: theta,
        basePhi: phi,
        noiseOffset: math.Random().nextDouble() * math.pi * 2,
        phaseOffset: math.Random().nextDouble() * math.pi * 2,
      ));
    }

    return particles;
  }

  double _smoothNoise(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;
    
    final u = fx * fx * (3 - 2 * fx);
    final v = fy * fy * (3 - 2 * fy);
    
    final n00 = _hash2D(ix, iy);
    final n10 = _hash2D(ix + 1, iy);
    final n01 = _hash2D(ix, iy + 1);
    final n11 = _hash2D(ix + 1, iy + 1);
    
    final nx0 = n00 * (1 - u) + n10 * u;
    final nx1 = n01 * (1 - u) + n11 * u;
    
    return nx0 * (1 - v) + nx1 * v;
  }

  double _hash2D(int x, int y) {
    final n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
    return (n - n.floor()) * 2 - 1;
  }

  double _fbm(double x, double y) {
    double value = 0;
    double amplitude = 1;
    double frequency = 1;
    double maxValue = 0;

    for (int i = 0; i < 2; i++) {
      value += amplitude * _smoothNoise(x * frequency, y * frequency);
      maxValue += amplitude;
      amplitude *= 0.5;
      frequency *= 2;
    }

    return value / maxValue;
  }

  Color _getParticleColor(double depth) {
    final colors = [
      widget.secondaryColor,
      widget.primaryColor,
      widget.accentColor,
      widget.highlightColor,
    ];

    final index = (depth * (colors.length - 1)).clamp(0, colors.length - 1);
    final t = (depth * (colors.length - 1)) - index.floor();

    final c1 = colors[index.floor()];
    final c2 = index < colors.length - 1 ? colors[index.ceil()] : colors.last;

    var color = Color.lerp(c1, c2, t)!;
    
    // Brighten all particles significantly for dark backgrounds
    final brighten = 0.3 + depth * 0.2;
    
    color = Color.fromRGBO(
      math.min(255, (color.red + (255 * brighten)).round()),
      math.min(255, (color.green + (255 * brighten)).round()),
      math.min(255, (color.blue + (255 * brighten)).round()),
      color.opacity,
    );
    
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ParticleSpherePainter(
          particles: _particles,
          time: _time,
          size: widget.size,
          getParticleColor: _getParticleColor,
          fbm: _fbm,
        ),
      ),
    );
  }
}

class Particle {
  final double baseTheta;
  final double basePhi;
  final double noiseOffset;
  final double phaseOffset;

  Particle({
    required this.baseTheta,
    required this.basePhi,
    required this.noiseOffset,
    required this.phaseOffset,
  });
}

class _ParticleSpherePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;
  final double size;
  final Color Function(double depth) getParticleColor;
  final double Function(double x, double y) fbm;

  _ParticleSpherePainter({
    required this.particles,
    required this.time,
    required this.size,
    required this.getParticleColor,
    required this.fbm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final baseRadius = this.size * 0.42;
    final breathe = math.sin(time * 0.12) * 0.03;
    final radius = baseRadius * (1 + breathe);

    final rotY = time ;  
    final rotX = math.sin(time) * 0.15 + 0.3;  

    final noiseTime = time * 0.02;

    final projected = <_ProjectedParticle>[];

    for (final p in particles) {
      final nx = p.baseTheta * 0.5;
      final ny = p.basePhi * 0.5;

      final wave = math.sin(noiseTime + p.noiseOffset) * 0.012;
      final tTheta = fbm(nx + noiseTime, ny + p.noiseOffset) * 0.03 + wave;
      final tPhi = fbm(nx + p.noiseOffset, ny + noiseTime) * 0.03;

      final theta = p.baseTheta + tTheta;
      final phi = p.basePhi + tPhi;

      final sinPhi = math.sin(phi);
      final cosPhi = math.cos(phi);

      var x = radius * sinPhi * math.cos(theta);
      var y = radius * cosPhi;
      var z = radius * sinPhi * math.sin(theta);

      final cosY = math.cos(rotY);
      final sinY = math.sin(rotY);
      final x1 = x * cosY - z * sinY;
      final z1 = z * cosY + x * sinY;

      final cosX = math.cos(rotX);
      final sinX = math.sin(rotX);
      final y1 = y * cosX - z1 * sinX;
      final z2 = z1 * cosX + y * sinX;

      const perspective = 500.0;
      final scale = perspective / (perspective + z2);

      final depth = (z2 + radius) / (2 * radius);

      projected.add(_ProjectedParticle(
        x: x1 * scale + cx,
        y: y1 * scale + cy,
        depth: depth,
        scale: scale,
        phaseOffset: p.phaseOffset,
      ));
    }

    projected.sort((a, b) => a.depth.compareTo(b.depth));

    for (final p in projected) {
      final baseSize = 0.35 + p.depth * 0.2;
      final pulse = 1 + math.sin(time * 0.15 + p.phaseOffset) * 0.05;

      final r = baseSize * p.scale * pulse * 2.5;
      final color = getParticleColor(p.depth);
      
      // Higher opacity for visibility on dark backgrounds
      final opacity = (0.65 + p.depth * 0.35).clamp(0.65, 1.0);

      final paint = Paint()
        ..color = color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p.x, p.y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleSpherePainter oldDelegate) =>
      oldDelegate.time != time;
}

class _ProjectedParticle {
  final double x;
  final double y;
  final double depth;
  final double scale;
  final double phaseOffset;

  _ProjectedParticle({
    required this.x,
    required this.y,
    required this.depth,
    required this.scale,
    required this.phaseOffset,
  });
}