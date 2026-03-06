import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/service_locator.dart';
import 'package:mood/core/ui_extensions.dart';
import 'package:mood/domain/models/message_model.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'chat_cubit.dart';
import 'chat_state.dart';

class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  late final ChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    _chatCubit = sl<ChatCubit>()..loadMessages(widget.receiverId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundTop,
      elevation: 0,
      leadingWidth: 70,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentGlow.withOpacity(0.2),
            child: Text(widget.receiverName[0].toUpperCase(), style: const TextStyle(color: AppColors.accentGlow)),
          ),
          12.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.receiverName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              Text('End-to-end encrypted', style: AppTextStyles.tagline.copyWith(fontSize: 10, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentGlow));
        }
        if (state is ChatError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        }
        if (state is ChatLoaded) {
          final messages = state.messages;
          if (messages.isEmpty) {
            return Center(child: Text('No messages yet', style: AppTextStyles.tagline));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            reverse: true, // Show latest at the bottom
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[messages.length - 1 - index];
              final isMe = msg.senderId == context.read<AuthCubit>().state.props[0] /* Should check user id */;
              // Note: AuthState props check is a bit brittle, ideally we have the user id directly accessible
              return _buildMessageBubble(msg, isMe: msg.senderId != widget.receiverId);
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: context.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accentGlow : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Text(
          message.content,
          style: AppTextStyles.body.copyWith(
            color: isMe ? AppColors.backgroundBottom : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTop.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTextStyles.tagline.copyWith(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            12.horizontalSpace,
            GestureDetector(
              onTap: () {
                final content = _messageController.text.trim();
                if (content.isNotEmpty) {
                  _chatCubit.sendMessage(widget.receiverId, content);
                  _messageController.clear();
                }
              },
              child: const CircleAvatar(
                backgroundColor: AppColors.accentGlow,
                child: Icon(Icons.send, color: AppColors.backgroundBottom, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
