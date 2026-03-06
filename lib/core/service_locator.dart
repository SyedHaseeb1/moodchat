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

  // Blocs/Cubits
  sl.registerFactory(() => AuthCubit(sl<AuthRepository>()));
  sl.registerFactory(() => ChatCubit(sl<ChatRepository>()));
  sl.registerFactory(() => ProfileCubit(sl<ProfileRepository>()));
}
