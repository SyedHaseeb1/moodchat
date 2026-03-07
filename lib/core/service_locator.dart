import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/supabase_auth_repository.dart';
import '../data/repositories/supabase_chat_repository.dart';
import '../data/repositories/supabase_profile_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../ui/auth/auth_cubit.dart';
import '../ui/chat_room/chat_cubit.dart';
import '../ui/profile/profile_cubit.dart';
import '../ui/friends/search_cubit.dart';
import '../ui/friends/friendship_cubit.dart';
import '../ui/friends/handshake_cubit.dart';
import '../ui/home/conversation_cubit.dart';
import '../domain/repositories/friendship_repository.dart';
import '../data/repositories/supabase_friendship_repository.dart';
import '../data/datasources/user_local_data_source.dart';
import 'presence_service.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Supabase
  final supabase = Supabase.instance.client;
  sl.registerLazySingleton<SupabaseClient>(() => supabase);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => SupabaseChatRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => SupabaseProfileRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<FriendshipRepository>(
    () => SupabaseFriendshipRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<UserLocalDataSource>(() => UserLocalDataSource());
  sl.registerLazySingleton<PresenceService>(
    () => PresenceService(sl<ProfileRepository>()),
  );

  // Blocs/Cubits
  sl.registerFactory(
    () => AuthCubit(
      sl<AuthRepository>(),
      sl<ProfileRepository>(),
      sl<UserLocalDataSource>(),
      sl<PresenceService>(),
    ),
  );
  sl.registerFactory(() => ChatCubit(sl<ChatRepository>()));
  sl.registerFactory(
    () => ProfileCubit(sl<ProfileRepository>(), sl<UserLocalDataSource>()),
  );
  sl.registerFactory(() => SearchCubit(sl<ProfileRepository>()));
  sl.registerFactory(() => FriendshipCubit(sl<FriendshipRepository>()));
  sl.registerFactory(() => HandshakeCubit(sl<ChatRepository>()));
  sl.registerFactory(() => ConversationCubit(sl<ChatRepository>()));
}
