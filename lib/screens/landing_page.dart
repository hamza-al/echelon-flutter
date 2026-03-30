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
  late Animation<double> _featuresOpacity;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _registerDevice();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _orbOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.45, curve: Curves.easeOut),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.55, curve: Curves.easeOut),
    );
    _featuresOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
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
    final sphereSize = (screenHeight * 0.22).clamp(140.0, 200.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.45),
                  radius: 0.9,
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

                  const Spacer(flex: 2),

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
                  const SizedBox(height: 8),

                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'Your AI-powered training partner.\nSpeak your sets. Track your nutrition.\nGet stronger every week.',
                      textAlign: TextAlign.center,
                      style: AppStyles.mainText().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  FadeTransition(
                    opacity: _featuresOpacity,
                    child: Row(
                      children: [
                        _featureChip(Icons.mic_none_rounded, 'Voice logging'),
                        const SizedBox(width: 8),
                        _featureChip(Icons.auto_awesome, 'AI coaching'),
                        const SizedBox(width: 8),
                        _featureChip(Icons.restaurant_menu_rounded, 'Nutrition'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  SlideTransition(
                    position: _buttonSlide,
                    child: FadeTransition(
                      opacity: _buttonOpacity,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OnboardingFlow(),
                                  ),
                                );
                              },
                              style: AppStyles.primaryButton(),
                              child: const Text('Get Started'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Takes less than 2 minutes to set up',
                            style: AppStyles.caption().copyWith(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
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

  Widget _featureChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.primaryLight.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
