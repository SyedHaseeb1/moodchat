import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_strings.dart';
import 'package:mood/core/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  final String title;

  const SplashScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.backgroundBottom,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Logo Section
            _buildLogo(),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              AppStrings.appName,
              style: AppTextStyles.h1,
            ).animate()
             .fadeIn(delay: 600.ms, duration: 800.ms)
             .slideY(begin: 0.3, end: 0),
            
            // Tagline
            Text(
              AppStrings.tagline,
              style: AppTextStyles.tagline,
            ).animate()
             .fadeIn(delay: 1000.ms, duration: 800.ms),
            
            const Spacer(flex: 2),
            
            // Loading Indicator
            _buildLoadingIndicator(),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlow.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: 120,
        height: 120,
      ),
    ).animate()
     .fadeIn(duration: 800.ms)
     .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.loading,
          style: AppTextStyles.loading,
        ).animate()
         .fadeIn(delay: 1000.ms, duration: 800.ms),
        const SizedBox(width: 8),
        SpinKitPulse(
          color: AppColors.accentGlow.withOpacity(0.5),
          size: 40,
        ),
      ],
    );
  }
}
