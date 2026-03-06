import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/service_locator.dart';
import 'package:mood/core/ui_extensions.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'package:mood/ui/auth/auth_state.dart';
import '../../core/logger.dart';
import '../../domain/models/user_model.dart' show UserModel;
import 'profile_cubit.dart';
import 'profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _profileCubit = sl<ProfileCubit>()..loadProfile(authState.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileCubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundTop,
          elevation: 0,
          title: Text('Settings', style: AppTextStyles.h2.copyWith(fontSize: 22)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            AppLogger.d('ProfileScreen: Current State: $state');
            
            if (state is ProfileInitial || state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentGlow));
            }
            
            if (state is ProfileError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                      24.verticalSpace,
                      Text('Something went wrong', style: AppTextStyles.h2),
                      8.verticalSpace,
                      Text(state.message, style: AppTextStyles.body, textAlign: TextAlign.center),
                      32.verticalSpace,
                      ElevatedButton(
                        onPressed: () {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is AuthAuthenticated) {
                            _profileCubit.loadProfile(authState.user);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGlow,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('RETRY', style: TextStyle(color: AppColors.backgroundBottom, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            if (state is ProfileLoaded) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    30.verticalSpace,
                    _buildProfileHeader(state.user),
                    40.verticalSpace,
                    _buildSectionTitle('ACCOUNT'),
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: 'Full Name',
                      subtitle: state.user.fullName ?? 'Not set',
                      onTap: () => _showEditDialog(context, 'Full Name', state.user.fullName ?? '', (val) => _profileCubit.updateFullName(val)),
                    ),
                    _buildSettingsTile(
                      icon: Icons.alternate_email,
                      title: 'Username',
                      subtitle: state.user.username != null ? '@${state.user.username}' : 'Not set',
                      onTap: null, // Username typically handled during registration or special flow
                    ),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: 'Bio',
                      subtitle: state.user.bio ?? 'Tell us about yourself...',
                      onTap: () => _showEditDialog(context, 'Bio', state.user.bio ?? '', (val) => _profileCubit.updateBio(val)),
                    ),
                    _buildSettingsTile(
                      icon: Icons.emoji_emotions_outlined,
                      title: 'Mood Status',
                      subtitle: state.user.moodStatus ?? 'Set status',
                      onTap: () => _showEditDialog(context, 'Mood Status', state.user.moodStatus ?? '', (val) => _profileCubit.updateMoodStatus(val)),
                    ),
                    _buildSettingsTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: state.user.phoneNumber ?? 'Add phone',
                      onTap: () => _showEditDialog(context, 'Phone Number', state.user.phoneNumber ?? '', (val) => _profileCubit.updatePhoneNumber(val)),
                    ),
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: 'Website',
                      subtitle: state.user.website ?? 'Add your website',
                      onTap: () => _showEditDialog(context, 'Website', state.user.website ?? '', (val) => _profileCubit.updateWebsite(val)),
                    ),
                    _buildSettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: state.user.email ?? 'Not available',
                      onTap: null,
                    ),
                    _buildSettingsTile(
                      icon: Icons.fingerprint,
                      title: 'User ID',
                      subtitle: state.user.id,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID copied to clipboard')));
                      },
                    ),
                    30.verticalSpace,
                    _buildSectionTitle('PRIVACY & SECURITY'),
                    _buildSettingsTile(
                      icon: Icons.history,
                      title: 'Last Updated',
                      subtitle: state.user.updatedAt != null
                        ? '${state.user.updatedAt!.day}/${state.user.updatedAt!.month}/${state.user.updatedAt!.year}'
                        : 'Recently',
                      onTap: null,
                    ),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'End-to-End Encryption',
                      subtitle: 'Verified keys active',
                      onTap: () {},
                    ),
                    40.verticalSpace,
                    _buildLogoutButton(context),
                    20.verticalSpace,
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );
  }
  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.accentGlow.withOpacity(0.1),
              child: user.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(user.avatarUrl!, fit: BoxFit.cover),
                    )
                  : Text(
                      user.fullName?[0].toUpperCase() ?? user.username?[0].toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 32, color: AppColors.accentGlow, fontWeight: FontWeight.bold),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.accentGlow, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 16, color: AppColors.backgroundBottom),
              ),
            ),
          ],
        ),
        16.verticalSpace,
        Text(user.fullName ?? 'Anonymous User', style: AppTextStyles.h2.copyWith(fontSize: 24)),
        Text(user.email??"nouser@decoderium.com", style: AppTextStyles.tagline),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: AppTextStyles.tagline.copyWith(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.accentGlow.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTextStyles.tagline.copyWith(fontSize: 13)),
        trailing: onTap != null ? const Icon(Icons.chevron_right, color: Colors.white38) : null,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AuthCubit>().signOut(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'LOG OUT',
            style: AppTextStyles.body.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
  void _showEditDialog(BuildContext context, String title, String currentVal, Function(String) onSave) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: title == 'Bio' ? 3 : 1,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter $title',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentGlow)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('SAVE', style: TextStyle(color: AppColors.accentGlow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
