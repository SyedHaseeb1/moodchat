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
  final String avatarUrl;
  final String conversationId;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.avatarUrl,
    required this.conversationId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatCubit _chatCubit;
  late final String _myId;

  @override
  void initState() {
    super.initState();
    _myId = context.read<AuthCubit>().getUserId();
    _chatCubit = sl<ChatCubit>()..loadMessages(widget.conversationId, _myId);
  }

  @override
  void dispose() {
    _chatCubit.clearActiveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentGlow.withOpacity(0.1),
            backgroundImage: widget.avatarUrl.isNotEmpty
                ? NetworkImage(widget.avatarUrl)
                : null,
            child: widget.avatarUrl.isEmpty
                ? Text(
                    widget.receiverName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accentGlow,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          12.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.receiverName,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'End-to-end encrypted',
                style: AppTextStyles.tagline.copyWith(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        // Scroll to bottom whenever new messages arrive
        if (state is ChatLoaded) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGlow),
          );
        }
        if (state is ChatError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (state is ChatLoaded) {
          final messages = state.messages;
          if (messages.isEmpty) {
            return Center(
              child: Text('No messages yet', style: AppTextStyles.tagline),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[messages.length - 1 - index];
              final isMe = msg.senderId == _myId;

              // Show date separator when day changes
              final showDateSep =
                  index == messages.length - 1 ||
                  !_isSameDay(
                    messages[messages.length - 1 - index].createdAt,
                    messages[messages.length - 2 - index].createdAt,
                  );

              return Column(
                children: [
                  if (showDateSep) _buildDateSeparator(msg.createdAt),
                  _buildMessageBubble(msg, isMe: isMe),
                ],
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.only(
          left: 14,
          right: isMe ? 8 : 14,
          top: 10,
          bottom: 8,
        ),
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
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: AppTextStyles.body.copyWith(
                color: isMe ? AppColors.backgroundBottom : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMsgTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? AppColors.backgroundBottom.withOpacity(0.6)
                        : Colors.white38,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildReceiptTick(message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Double-tick read receipt indicator (only shown on sender's bubbles).
  ///
  /// States:
  /// • Sent     → single grey tick  (isRead = false, no receiver yet)
  /// • Received → double grey ticks (message exists in DB, receiver got it)
  /// • Read     → double blue ticks (isRead = true)
  Widget _buildReceiptTick(MessageModel message) {
    // If isRead = true → blue double tick
    // If message is in DB (has id) → double grey tick (delivered/received)
    // The "sent" single tick state is only meaningful immediately after sending
    // before the stream returns the persisted row. Since we rely on the stream,
    // all messages shown here are already in DB ⇒ at least "received".
    final isRead = message.isRead;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // First tick
        Icon(
          Icons.check,
          size: 14,
          color: isRead
              ? Colors.blue[300]
              : AppColors.backgroundBottom.withOpacity(0.5),
        ),
        // Second tick (offset to the right → double check)
        Positioned(
          left: 5,
          child: Icon(
            Icons.check,
            size: 14,
            color: isRead
                ? Colors.blue[300]
                : AppColors.backgroundBottom.withOpacity(0.5),
          ),
        ),
        // Spacer so the Stack has width
        const SizedBox(width: 16),
      ],
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
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTextStyles.tagline.copyWith(
                      color: Colors.white38,
                    ),
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
                  _chatCubit.sendMessage(
                    widget.conversationId,
                    widget.receiverId,
                    content,
                  );
                  _messageController.clear();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.accentGlow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.backgroundBottom,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMsgTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
