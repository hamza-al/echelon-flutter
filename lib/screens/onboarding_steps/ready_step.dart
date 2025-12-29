import 'package:flutter/material.dart';
import '../../styles.dart';
import '../../widgets/pulsing_particle_sphere.dart';

class ReadyStep extends StatelessWidget {
  const ReadyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PulsingParticleSphere(
            size: 140,
            primaryColor: AppColors.primary,
            secondaryColor: AppColors.primaryLight,
            accentColor: AppColors.primaryDark,
            highlightColor: AppColors.primary,
          ),
          SizedBox(height: screenHeight * 0.05),
          Text(
            'Echelon is ready.',
            style: AppStyles.mainHeader().copyWith(
              fontSize: 36,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.03),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'I\'ll guide you through every workout — hands-free.',
              style: AppStyles.questionText().copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

