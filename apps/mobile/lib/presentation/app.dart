// ignore_for_file: uri_does_not_exist, undefined_identifier, non_constant_list_element
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:last_mile_tracker/l10n/app_localizations.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/onboarding_provider.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';
import 'pages/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LastMileTrackerApp extends ConsumerWidget {
  const LastMileTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final hasSeenOnboarding = ref.watch(onboardingProvider);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Last Mile Tracker',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
      ],
      navigatorKey: navigatorKey,
      theme: AppTheme.getTheme(themeState, context),
      home: hasSeenOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}
