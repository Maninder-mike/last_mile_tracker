import 'package:flutter/cupertino.dart';
import 'pages/home_page.dart';

class LastMileTrackerApp extends StatelessWidget {
  const LastMileTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Last Mile Tracker',
      theme: CupertinoThemeData(
        brightness: null, // Follow system
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoDynamicColor.withBrightness(
          color: CupertinoColors.systemGroupedBackground,
          darkColor: CupertinoColors.black,
        ),
        barBackgroundColor: CupertinoDynamicColor.withBrightness(
          color: Color(0xCCF2F2F7),
          darkColor: Color(0xCC1C1C1E),
        ),
      ),
      home: const HomePage(),
    );
  }
}
