import 'dart:math' as math;
import 'dart:ui';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double page = 0.0;
          if (_controller.hasClients) {
            page = _controller.page ?? 0.0;
          } else {
            page = _currentPage.toDouble();
          }

          // Calculate interpolated background color
          final int index1 = page.floor().clamp(0, _slides.length - 1);
          final int index2 = page.ceil().clamp(0, _slides.length - 1);
          final double progress = page - page.floor();
          final Color color1 = _slides[index1].color;
          final Color color2 = _slides[index2].color;
          final Color interpolatedColor = Color.lerp(color1, color2, progress) ?? color1;

          return Stack(
            children: [
              // 1. Pure black base
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.black,
                ),
              ),

              // 2. Floating aura blobs
              Positioned.fill(
                child: _FloatingBlobsBackground(themeColor: interpolatedColor),
              ),

              // 3. High blur filter to blend blobs into soft aura gradients
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
                    child: Container(color: CupertinoColors.transparent),
                  ),
                ),
              ),

              // 4. Subtle Radial Gradient Overlay to blend and darken for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        interpolatedColor.withValues(alpha: 0.12),
                        CupertinoColors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Main content and page controller controls
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

                          // Scroll relative offset for this page
                          final double pageOffset = page - index;

                          // 3D perspective rotation matrix
                          final tiltTransform = Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateY(pageOffset * 0.25)
                            ..translateByDouble(pageOffset * -90.0, 0.0, 0.0, 0.0);

                          Widget animatedIcon = GlassContainer(
                            padding: const EdgeInsets.all(40),
                            borderRadius: AppTheme.radiusLarge,
                            border: Border.all(
                              color: slide.color.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            child: Icon(
                              slide.icon,
                              size: 100,
                              color: slide.color,
                            ),
                          );

                          // Smooth continuous float
                          animatedIcon = animatedIcon
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: -8, end: 8, duration: 2.seconds, curve: Curves.easeInOut);

                          // Slide/scale-in entry animation
                          animatedIcon = animatedIcon
                              .animate(key: ValueKey('icon_${index}_${_currentPage == index}'))
                              .scale(duration: 600.ms, curve: Curves.easeOutBack)
                              .fadeIn(duration: 500.ms);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform(
                                  transform: tiltTransform,
                                  alignment: Alignment.center,
                                  child: animatedIcon,
                                ),
                                const SizedBox(height: 60),
                                Transform.translate(
                                  offset: Offset(pageOffset * -40.0, 0),
                                  child: Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.heading1.copyWith(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                  .animate(key: ValueKey('title_${index}_${_currentPage == index}'))
                                  .fadeIn(delay: 150.ms, duration: 500.ms)
                                  .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutQuad),
                                ),
                                const SizedBox(height: 20),
                                Transform.translate(
                                  offset: Offset(pageOffset * -20.0, 0),
                                  child: Text(
                                    slide.description,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(
                                      color: CupertinoColors.systemGrey,
                                      height: 1.4,
                                    ),
                                  )
                                  .animate(key: ValueKey('desc_${index}_${_currentPage == index}'))
                                  .fadeIn(delay: 250.ms, duration: 500.ms)
                                  .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutQuad),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Navigation bar (bottom controls)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () =>
                                ref.read(onboardingProvider.notifier).markAsSeen(),
                          ),

                          // Dynamic dot indicator (Expanding dots)
                          Row(
                            children: List.generate(
                              _slides.length,
                              (index) {
                                final double selectFactor =
                                    (1.0 - (page - index).abs()).clamp(0.0, 1.0);
                                final double dotWidth = 8.0 + (16.0 * selectFactor);
                                final Color dotColor = Color.lerp(
                                  CupertinoColors.systemGrey.withValues(alpha: 0.35),
                                  _slides[index].color,
                                  selectFactor,
                                )!;

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: dotWidth,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: dotColor,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Transparent dynamic glassmorphic Button
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: interpolatedColor.withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 10,
                                  ),
                                  color: interpolatedColor.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(24),
                                  child: AnimatedSwitcher(
                                    duration: 250.ms,
                                    child: Text(
                                      _currentPage == _slides.length - 1
                                          ? 'Start'
                                          : 'Next',
                                      key: ValueKey(_currentPage == _slides.length - 1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_currentPage < _slides.length - 1) {
                                      _controller.nextPage(
                                        duration: 500.ms,
                                        curve: Curves.easeInOutCubic,
                                      );
                                    } else {
                                      ref.read(onboardingProvider.notifier).markAsSeen();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

class _FloatingBlobsBackground extends StatefulWidget {
  final Color themeColor;

  const _FloatingBlobsBackground({required this.themeColor});

  @override
  State<_FloatingBlobsBackground> createState() => _FloatingBlobsBackgroundState();
}

class _FloatingBlobsBackgroundState extends State<_FloatingBlobsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BlobsPainter(
            animationValue: _controller.value,
            color: widget.themeColor,
          ),
        );
      },
    );
  }
}

class _BlobsPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _BlobsPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Blob 1: Top Right
    final angle1 = animationValue * 2 * math.pi;
    final x1 = size.width * 0.75 + math.cos(angle1) * size.width * 0.15;
    final y1 = size.height * 0.2 + math.sin(angle1) * size.height * 0.08;
    canvas.drawCircle(Offset(x1, y1), size.width * 0.45, paint);

    // Blob 2: Center Left (moves in opposite direction)
    final angle2 = -animationValue * 2 * math.pi + math.pi;
    final x2 = size.width * 0.2 + math.cos(angle2) * size.width * 0.1;
    final y2 = size.height * 0.5 + math.sin(angle2) * size.height * 0.12;
    paint.color = color.withValues(alpha: 0.10);
    canvas.drawCircle(Offset(x2, y2), size.width * 0.5, paint);

    // Blob 3: Bottom Right / Center Right
    final angle3 = animationValue * 2 * math.pi * 1.5;
    final x3 = size.width * 0.6 + math.sin(angle3) * size.width * 0.12;
    final y3 = size.height * 0.8 + math.cos(angle3) * size.height * 0.08;
    paint.color = color.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(x3, y3), size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
