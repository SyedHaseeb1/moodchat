import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/ui_extensions.dart';
import 'package:mood/domain/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'package:mood/ui/auth/auth_state.dart';
import 'package:mood/ui/friends/friendship_cubit.dart';
import 'package:mood/ui/chat_room/chat_room_screen.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/service_locator.dart';
import 'package:mood/core/logger.dart';

class QRProfileScreen extends StatefulWidget {
  const QRProfileScreen({super.key});

  @override
  State<QRProfileScreen> createState() => _QRProfileScreenState();
}

class _QRProfileScreenState extends State<QRProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Share Profile', style: AppTextStyles.h2),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGlow,
          tabs: const [
            Tab(text: 'MY CODE'),
            Tab(text: 'SCAN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCode(user),
          _buildScanner(user.id),
        ],
      ),
    );
  }

  Widget _buildMyCode(UserModel user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGlow.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: QrImageView(
              data: user.id,
              version: QrVersions.auto,
              size: 240.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.backgroundBottom),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.backgroundBottom),
            ),
          ),
          const SizedBox(height: 48),
          Text(user.fullName ?? 'User', style: AppTextStyles.h2),
          Text('@${user.username}', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 24),
          const Text(
            'Others can scan this to instantly\nadd you as a friend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner(String currentUserId) {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && !_isScanning) {
                final friendId = barcode.rawValue!;
                _isScanning = true;
                _onFriendScanned(currentUserId, friendId);
              }
            }
          },
        ),
        _buildScannerOverlay(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentGlow, width: 4),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Scan a friend\'s QR code', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onFriendScanned(String currentUserId, String friendId) async {
    if (currentUserId == friendId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait, that\'s you!')));
      setState(() => _isScanning = false);
      return;
    }

    AppLogger.i('Scanned friend ID: $friendId');
    
    // Call friendship cubit to add instantly
    context.read<FriendshipCubit>().addInstantFriend(currentUserId, friendId);
    
    // 2. Trigger handshake (so they navigate)
    await sl<ChatRepository>().triggerInstantNavigation(friendId);
    
    // 3. Get/Create conversation (so I navigate)
    final conversationId = await sl<ChatRepository>().getOrCreateConversation(currentUserId, friendId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instant handshake complete! 🤝'),
          backgroundColor: Colors.greenAccent,
        ),
      );
      
      // 4. Navigate to Chat instantly
      context.pushReplacement(ChatRoomScreen(
        receiverId: friendId,
        receiverName: 'New Friend',
        conversationId: conversationId,
      ));
    }
  }
}
