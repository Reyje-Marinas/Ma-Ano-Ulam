import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main/main_navigation_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class MealMateApp extends StatelessWidget {
  const MealMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.main: (context) => const MainNavigationScreen(),
      },
    );
  }
}