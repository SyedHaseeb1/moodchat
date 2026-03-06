import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'package:mood/ui/friends/handshake_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mood/core/supabase_config.dart';
import 'package:mood/core/service_locator.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/logger.dart';
import 'package:mood/ui/SplashScreen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'domain/repositories/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await dotenv.load(fileName: ".env");
  AppLogger.i('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  AppLogger.i('Supabase initialized successfully.');
  await initServiceLocator();
  AppLogger.i('Service Locator initialized.');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final authCubit = sl<AuthCubit>();
    final userId = authCubit.getUserId();
    if (userId.isEmpty) return;

    if (state == AppLifecycleState.resumed) {
      sl<ProfileRepository>().updateOnlineStatus(userId, true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      sl<ProfileRepository>().updateOnlineStatus(userId, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<HandshakeCubit>(create: (_) => sl<HandshakeCubit>()..startListening()),
      ],
      child: MaterialApp(
        title: 'Mood',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: AppColors.accentGlow,
        ),
        home: const SplashScreen(title: ''),
      ),
    );
  }
}
