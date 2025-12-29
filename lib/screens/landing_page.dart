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

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    // Register device when landing page opens
    _registerDevice();
  }

  Future<void> _registerDevice() async {
    final authService = context.read<AuthService>();
    await authService.register();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const PulsingParticleSphere(
                size: 200,
                primaryColor: AppColors.primary,
                secondaryColor: AppColors.primaryLight,
                accentColor: AppColors.primaryDark,
                highlightColor: AppColors.primary,
              ),
              const SizedBox(height: 40),
              Text(
                'Echelon',
                style: AppStyles.mainHeader(),
              ),
              const SizedBox(height: 24),
              Text(
                'Push the boundaries of your \nphysical limits',
                style: AppStyles.mainText().copyWith(
                  color: AppColors.accent.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const OnboardingFlow(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Start Training',
                    style: AppStyles.mainText().copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

