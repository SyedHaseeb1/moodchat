import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_strings.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/glass_container.dart';
import 'package:mood/core/ui_extensions.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: AppTextStyles.h1.copyWith(fontSize: 36),
                ).animate().fadeIn().slideX(begin: -0.2),
                
                8.verticalSpace,
                
                Text(
                  _isLogin ? 'Sign in to continue chatting' : 'Join the private world of Mood',
                  style: AppTextStyles.tagline,
                ).animate().fadeIn(delay: 200.ms),
                
                32.verticalSpace,
                
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        hintText: AppStrings.email,
                        icon: Icons.email_outlined,
                      ),
                      16.verticalSpace,
                      _buildTextField(
                        controller: _passwordController,
                        hintText: AppStrings.password,
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      32.verticalSpace,
                      _buildSubmitButton(),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                
                24.verticalSpace,
                
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                      style: AppTextStyles.tagline.copyWith(color: AppColors.accentGlow),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.tagline,
          prefixIcon: Icon(icon, color: AppColors.secondaryText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
          );
        }
        if (state is AuthAuthenticated) {
             // Will handle navigation later
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const CircularProgressIndicator(color: AppColors.accentGlow);
        }
        
        return GestureDetector(
          onTap: () {
            final email = _emailController.text.trim();
            final password = _passwordController.text.trim();
            if (_isLogin) {
              context.read<AuthCubit>().signIn(email, password);
            } else {
              context.read<AuthCubit>().signUp(email, password);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGlow, Color(0xFF6E51FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGlow.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _isLogin ? AppStrings.login : AppStrings.register,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
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
