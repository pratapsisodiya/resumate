import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/screens/home_screen.dart';
import 'package:resumate/screens/onboarding_screen.dart';
import 'package:resumate/shared/theme/app_theme.dart';

class ResumateApp extends StatelessWidget {
  final bool showOnboarding;
  const ResumateApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Resumate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
      ),
    );
  }
}
