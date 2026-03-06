import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/ui/auth/auth_cubit.dart';

import '../auth/auth_state.dart';
import '../chat_room/chat_room_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/ui_extensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundTop,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.push(const ProfileScreen()),
            child: CircleAvatar(
              backgroundColor: AppColors.accentGlow.withOpacity(0.1),
              backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.fullName?[0].toUpperCase() ?? user?.username?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(color: AppColors.accentGlow, fontSize: 14),
                    )
                  : null,
            ),
          ),
        ),
        title: Text('Mood', style: AppTextStyles.h2.copyWith(fontSize: 24)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildChatItem(
            context,
            name: 'Sarah (Mock Chat)',
            id: 'mock-uuid-1',
            lastMsg: 'Hey! Ready for the meeting?',
            time: '12:45',
          ),
          _buildChatItem(
            context,
            name: 'Developer (Test)',
            id: 'mock-uuid-2',
            lastMsg: 'The new encryption layer is live.',
            time: 'Yesterday',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accentGlow,
        child: const Icon(Icons.message, color: AppColors.backgroundBottom),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, {
    required String name,
    required String id,
    required String lastMsg,
    required String time,
  }) {
    return ListTile(
      onTap: () => context.push(ChatRoomScreen(receiverId: id, receiverName: name)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.accentGlow.withOpacity(0.1),
        child: Text(name[0], style: const TextStyle(color: AppColors.accentGlow, fontSize: 20)),
      ),
      title: Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(lastMsg, style: AppTextStyles.tagline, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: AppTextStyles.tagline.copyWith(fontSize: 12)),
    );
  }
}
