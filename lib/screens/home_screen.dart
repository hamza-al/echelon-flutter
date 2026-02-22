import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';
import 'active_workout_screen.dart';
import 'profile_screen.dart';
import 'log_class_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout',
                          style: AppStyles.mainHeader().copyWith(
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join the upper echelon of fitness',
                          style: AppStyles.questionSubtext(),
                        ),
                      ],
                    ),
                  ),
                  // Profile icon
                  IconButton(
                    icon: const Icon(
                      Icons.person_outline,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              // Center sphere
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const ActiveWorkoutScreen(),
                              transitionDuration: const Duration(milliseconds: 500),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'workout_sphere',
                          child: const PulsingParticleSphere(
                            size: 220,
                            primaryColor: AppColors.primary,
                            secondaryColor: AppColors.primaryLight,
                            accentColor: AppColors.primaryDark,
                            highlightColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Tap to start your workout',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'I\'m listening and ready to log',
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LogClassScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 18,
                                color: AppColors.accent.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Log a Class',
                                style: AppStyles.mainText().copyWith(
                                  fontSize: 14,
                                  color: AppColors.accent.withOpacity(0.6),
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
        ),
      ),
    );
  }
}

