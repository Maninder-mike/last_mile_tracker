import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/onboarding_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    const _OnboardingSlide(
      title: 'Live Fleet Tracking',
      description:
          'Monitor your fleet with real-time map updates and smoothed marker movements.',
      icon: CupertinoIcons.map_fill,
      color: CupertinoColors.activeBlue,
    ),
    const _OnboardingSlide(
      title: 'Smart Shipments',
      description:
          'Organize your logistics with powerful filters and intuitive swipe actions.',
      icon: CupertinoIcons.cube_box_fill,
      color: CupertinoColors.systemIndigo,
    ),
    const _OnboardingSlide(
      title: 'Sensor Telemetry',
      description:
          'Connect to ESP32 trackers via BLE to monitor temperature and battery health.',
      icon: CupertinoIcons.antenna_radiowaves_left_right,
      color: CupertinoColors.systemPurple,
    ),
    const _OnboardingSlide(
      title: 'Deep Analytics',
      description:
          'Visualize performance trends and health metrics with interactive charts.',
      icon: CupertinoIcons.graph_square_fill,
      color: CupertinoColors.systemOrange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _slides[_currentPage].color.withValues(alpha: 0.3),
                        CupertinoColors.black,
                      ],
                    ),
                  ),
                ),
              )
              .animate(target: _currentPage.toDouble())
              .custom(
                duration: 800.ms,
                builder: (context, value, child) => child,
              ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassContainer(
                              padding: const EdgeInsets.all(40),
                              child: Icon(
                                slide.icon,
                                size: 100,
                                color: slide.color,
                              ),
                            ).animate().scale(delay: 200.ms).fadeIn(),
                            const SizedBox(height: 60),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: AppTheme.heading1.copyWith(
                                color: CupertinoColors.white,
                              ),
                            ).animate().slideY(begin: 0.2, end: 0).fadeIn(),
                            const SizedBox(height: 20),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: AppTheme.body.copyWith(
                                color: CupertinoColors.systemGrey,
                              ),
                            ).animate().slideY(begin: 0.3, end: 0).fadeIn(),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Pagination & Buttons
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                        onPressed: () =>
                            ref.read(onboardingProvider.notifier).markAsSeen(),
                      ),

                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? _slides[_currentPage].color
                                  : CupertinoColors.systemGrey.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: _slides[_currentPage].color,
                        child: Text(
                          _currentPage == _slides.length - 1 ? 'Start' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _controller.nextPage(
                              duration: 400.ms,
                              curve: Curves.easeInOut,
                            );
                          } else {
                            ref.read(onboardingProvider.notifier).markAsSeen();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
