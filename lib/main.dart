import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mood/ui/auth/auth_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mood/core/supabase_config.dart';
import 'package:mood/core/service_locator.dart';
import 'package:mood/core/app_colors.dart';
import 'package:mood/core/logger.dart';
import 'package:mood/ui/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
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
