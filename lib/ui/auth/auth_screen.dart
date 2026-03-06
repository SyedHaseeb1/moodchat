import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_strings.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/glass_container.dart';
import 'package:mood/core/ui_extensions.dart';
import '../home/home_screen.dart';
import '../profile/profile_setup_screen.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

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
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Branding Section
                _buildBrandSection().animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                
                const Spacer(),
                
                // Action Section
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Secure Access',
                          style: AppTextStyles.h2.copyWith(fontSize: 24),
                        ),
                        12.verticalSpace,
                        Text(
                          'Sign in to your private vault with Google',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.tagline,
                        ),
                        32.verticalSpace,
                        _buildGoogleButton(context),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                
                const Spacer(),
                
                // Footer
                Text(
                  'End-to-End Encrypted',
                  style: AppTextStyles.tagline.copyWith(fontSize: 12, color: Colors.white24),
                ).animate().fadeIn(delay: 1000.ms),
                
                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection() {
    return Column(
      children: [
        Image.asset(
          'assets/icon/app_icon.png',
          width: 140,
          height: 140,
        ),
        16.verticalSpace,
        Text(
          AppStrings.appName,
          style: AppTextStyles.h1.copyWith(letterSpacing: 4),
        ),
        Text(
          AppStrings.tagline,
          style: AppTextStyles.tagline.copyWith(letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (state is AuthAuthenticated) {
          context.pushReplacement(const HomeScreen());
        } else if (state is AuthNeedsProfileSetup) {
          context.pushReplacement(ProfileSetupScreen(user: state.user));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return GestureDetector(
          onTap: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: AppColors.backgroundBottom, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.g_mobiledata_rounded, color: AppColors.backgroundBottom, size: 28),
                        8.horizontalSpace,
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.backgroundBottom,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// Add padding to GlassContainer since I missed it in the widget definition
extension on GlassContainer {
  Widget padding(EdgeInsetsGeometry padding) => Padding(padding: padding, child: this);
}
