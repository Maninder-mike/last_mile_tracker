import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/onboarding_provider.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';
import 'pages/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';

class LastMileTrackerApp extends ConsumerWidget {
  const LastMileTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final hasSeenOnboarding = ref.watch(onboardingProvider);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Last Mile Tracker',
      theme: AppTheme.getTheme(themeState, context),
      home: hasSeenOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}
