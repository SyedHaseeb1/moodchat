import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/ui/auth/auth_cubit.dart';

import '../../core/ui_extensions.dart';
import '../../domain/repositories/chat_repository.dart';
import '../auth/auth_state.dart';
import '../chat_room/chat_room_screen.dart';
import '../profile/profile_screen.dart';
import '../friends/people_discovery_screen.dart';
import '../friends/qr_profile_screen.dart';
import '../friends/friendship_cubit.dart';
import '../friends/handshake_cubit.dart';
import 'conversation_cubit.dart';
import '../../domain/models/conversation_model.dart';
import '../../core/service_locator.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FriendshipCubit>()..loadFriendships(user?.id ?? '')),
        BlocProvider(create: (_) => sl<ConversationCubit>()..loadConversations(user?.id ?? '')),
      ],
      child: BlocListener<HandshakeCubit, HandshakeState>(
        listener: (context, state) async {
          if (state is HandshakeReceived) {
            // Instant navigation logic
            final otherUserId = state.triggerUserId;
            final myId = context.read<AuthCubit>().getUserId();
            
            // 1. Force consume the event so it doesn't trigger twice
            context.read<HandshakeCubit>().consume(otherUserId);
            
            // 2. Resolve conversation and navigate
            final conversationId = await sl<ChatRepository>().getOrCreateConversation(myId, otherUserId);
            
            // 3. Fetch profile for a better experience
            final otherUser = await sl<ProfileRepository>().getProfile(otherUserId);
            
            // 4. Navigate instantly
            if (context.mounted) {
              context.push(ChatRoomScreen(
                receiverId: otherUserId,
                receiverName: otherUser.fullName ?? otherUser.username ?? 'New Friend',
                conversationId: conversationId,
              ));
            }
          }
        },
        child: Scaffold(
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
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.fullName?[0].toUpperCase() ??
                              user?.username?[0].toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            color: AppColors.accentGlow,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            title: Text('Mood', style: AppTextStyles.h2.copyWith(fontSize: 24)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.person_add_outlined,
                  color: Colors.white70,
                ),
                onPressed: () => context.push(const PeopleDiscoveryScreen()),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<FriendshipCubit>(),
                        child: const QRProfileScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: BlocBuilder<ConversationCubit, ConversationState>(
            builder: (context, state) {
              if (state is ConversationLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGlow),
                );
              }
              if (state is ConversationError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              if (state is ConversationLoaded) {
                final conversations = state.conversations;
                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.white10,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push(const PeopleDiscoveryScreen()),
                          icon: const Icon(Icons.search),
                          label: const Text('FIND FRIENDS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGlow,
                            foregroundColor: AppColors.backgroundBottom,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final otherUserId = conv.user1Id == user?.id ? conv.user2Id : conv.user1Id;
                    final unreadCount = conv.user1Id == user?.id ? conv.user1UnreadCount : conv.user2UnreadCount;

                    return FutureBuilder<UserModel>(
                      future: sl<ProfileRepository>().getProfile(otherUserId),
                      builder: (context, snapshot) {
                        final otherUser = snapshot.data;
                        return _buildChatItem(
                          context,
                          name: otherUser?.fullName ?? otherUser?.username ?? '...',
                          id: otherUserId,
                          conversationId: conv.id,
                          lastMsg: conv.lastMessageText ?? 'No messages yet',
                          unreadCount: unreadCount,
                          isOnline: otherUser?.isOnline ?? false,
                          time: conv.lastMessageAt != null ? _formatTime(conv.lastMessageAt!) : '',
                          avatarUrl: otherUser?.avatarUrl,
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppColors.accentGlow,
            child: const Icon(Icons.message, color: AppColors.backgroundBottom),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context, {
    required String name,
    required String id,
    required String conversationId,
    required String lastMsg,
    required int unreadCount,
    required String time,
    bool isOnline = false,
    String? avatarUrl,
  }) {
    return ListTile(
      onTap: () => context.push(ChatRoomScreen(
        receiverId: id,
        receiverName: name,
        conversationId: conversationId,
      )),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accentGlow.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.accentGlow,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundBottom, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        lastMsg,
        style: AppTextStyles.tagline.copyWith(
          color: unreadCount > 0 ? Colors.white : Colors.white38,
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: AppTextStyles.tagline.copyWith(
              fontSize: 12,
              color: unreadCount > 0 ? AppColors.accentGlow : Colors.white24,
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: AppColors.backgroundBottom,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekDays[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
