import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/app_text_styles.dart';
import 'package:mood/core/ui_extensions.dart';
import 'package:mood/ui/friends/search_cubit.dart';
import 'package:mood/ui/friends/friendship_cubit.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'package:mood/ui/auth/auth_state.dart';
import 'package:mood/domain/models/user_model.dart';
import 'package:mood/core/service_locator.dart';

class PeopleDiscoveryScreen extends StatefulWidget {
  const PeopleDiscoveryScreen({super.key});

  @override
  State<PeopleDiscoveryScreen> createState() => _PeopleDiscoveryScreenState();
}

class _PeopleDiscoveryScreenState extends State<PeopleDiscoveryScreen> {
  final _searchController = TextEditingController();
  late final SearchCubit _searchCubit;
  late final FriendshipCubit _friendshipCubit;

  @override
  void initState() {
    super.initState();
    _searchCubit = sl<SearchCubit>();
    _friendshipCubit = sl<FriendshipCubit>();
    
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _friendshipCubit.loadFriendships(authState.user.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _searchCubit),
        BlocProvider.value(value: _friendshipCubit),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Find Friends', style: AppTextStyles.h2),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accentGlow));
                  }
                  if (state is SearchResults) {
                    return _buildSearchResults(state.users);
                  }
                  if (state is SearchError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
                  }
                  return _buildPendingRequestsSection();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => _searchCubit.search(val),
        decoration: InputDecoration(
          hintText: 'Search by username or name...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: const Icon(Icons.search, color: AppColors.accentGlow),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: Colors.white38)));
    }

    final currentUser = (context.read<AuthCubit>().state as AuthAuthenticated).user;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        if (user.id == currentUser.id) return const SizedBox.shrink();

        return _buildUserTile(user, currentUser.id);
      },
    );
  }

  Widget _buildUserTile(UserModel user, String currentUserId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentGlow.withOpacity(0.2),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? Text(user.fullName?[0] ?? '?', style: const TextStyle(color: AppColors.accentGlow)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('@${user.username ?? 'user'}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _friendshipCubit.sendRequest(currentUserId, user.id),
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.accentGlow),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection() {
    return BlocBuilder<FriendshipCubit, FriendshipState>(
      builder: (context, state) {
        if (state is FriendshipLoaded && state.pendingRequests.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('PENDING REQUESTS', style: AppTextStyles.tagline.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final req = state.pendingRequests[index];
                    final profile = req['profiles'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentGlow.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Text(profile['full_name']?[0] ?? '?'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Text('wants to be friends', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _friendshipCubit.acceptRequest(req['id']),
                            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                          ),
                          IconButton(
                            onPressed: () => _friendshipCubit.rejectRequest(req['id']),
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.white10),
              SizedBox(height: 16),
              Text('Search to find new friends', style: TextStyle(color: Colors.white10)),
            ],
          ),
        );
      },
    );
  }
}
