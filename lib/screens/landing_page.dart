import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';
import '../services/auth_service.dart';
import 'onboarding_flow.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _orbOpacity;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _tagsOpacity;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _registerDevice();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _orbOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _tagsOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _registerDevice() async {
    final authService = context.read<AuthService>();
    await authService.register();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sphereSize = (screenHeight * 0.32).clamp(200.0, 300.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 0.85,
                  colors: [
                    const Color(0xFF110E18),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  FadeTransition(
                    opacity: _orbOpacity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: sphereSize * 1.6,
                          height: sphereSize * 1.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.08),
                                const Color(0xFFA78BFA)
                                    .withValues(alpha: 0.03),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        PulsingParticleSphere(size: sphereSize),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  FadeTransition(
                    opacity: _titleOpacity,
                    child: Text(
                      'Echelon',
                      style: AppStyles.mainHeader().copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'Voice-powered coaching',
                      style: AppStyles.mainText().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _tagsOpacity,
                    child: Text(
                      'Strength  ·  Nutrition  ·  Voice',
                      style: AppStyles.caption().copyWith(
                        letterSpacing: 1,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SlideTransition(
                    position: _buttonSlide,
                    child: FadeTransition(
                      opacity: _buttonOpacity,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const OnboardingFlow(),
                              ),
                            );
                          },
                          style: AppStyles.primaryButton(),
                          child: const Text('Begin'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
