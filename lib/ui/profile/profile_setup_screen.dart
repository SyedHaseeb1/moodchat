import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/ui_extensions.dart';
import 'package:mood/domain/models/user_model.dart';
import 'package:mood/domain/repositories/profile_repository.dart';
import 'package:mood/core/service_locator.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'package:mood/ui/home/home_screen.dart';
import 'package:mood/core/logger.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserModel user;

  const ProfileSetupScreen({super.key, required this.user});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  bool _isLoading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim().toLowerCase();
      final isAvailable = await sl<ProfileRepository>().isUsernameAvailable(username);

      if (!isAvailable) {
        setState(() {
          _usernameError = 'Username is already taken';
          _isLoading = false;
        });
        return;
      }

      final updatedUser = widget.user.copyWith(
        fullName: _nameController.text.trim(),
        username: username,
        updatedAt: DateTime.now(),
      );

      await sl<ProfileRepository>().updateProfile(updatedUser);
      AppLogger.i('Profile setup complete for ${updatedUser.id}');

      if (!mounted) return;
      
      // Trigger a re-check in AuthCubit or just navigate
      // Since AuthCubit emitted AuthNeedsProfileSetup, it won't automatically re-emit AuthAuthenticated 
      // unless we tell it to or we manually push the next screen.
      // Re-checking is cleaner.
      context.read<AuthCubit>().checkInitialAuth(); // Re-check to update state to Authenticated
      context.pushReplacement(const HomeScreen());
    } catch (e) {
      AppLogger.e('Profile Setup Error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.face_retouching_natural, size: 64, color: AppColors.accentGlow),
              const SizedBox(height: 24),
              Text('Complete Your Profile', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Tell us how people should identify you in the Mood community.',
                style: AppTextStyles.tagline,
              ),
              const SizedBox(height: 48),
              
              // Full Name field
              Text('FULL NAME', style: AppTextStyles.tagline.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. John Doe',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGlow)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 32),

              // Username field
              Text('USERNAME', style: AppTextStyles.tagline.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: AppColors.accentGlow, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '@',
                  prefixStyle: const TextStyle(color: AppColors.accentGlow),
                  hintText: 'john_doe',
                  hintStyle: const TextStyle(color: Colors.white24),
                  errorText: _usernameError,
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGlow)),
                ),
                onChanged: (_) => setState(() => _usernameError = null),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Username is required';
                  if (val.length < 3) return 'Too short';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) return 'Letters, numbers, and underscores only';
                  return null;
                },
              ),
              
              const SizedBox(height: 64),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGlow,
                    foregroundColor: AppColors.backgroundBottom,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: AppColors.accentGlow.withOpacity(0.4),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.backgroundBottom))
                    : const Text('GET STARTED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
