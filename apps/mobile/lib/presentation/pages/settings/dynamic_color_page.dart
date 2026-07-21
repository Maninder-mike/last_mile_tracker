import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/providers/theme_provider.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import '../../widgets/floating_header.dart';
import 'widgets/glass_settings_section.dart';

class WallpaperOption {
  final String name;
  final Color seedColor;
  final LinearGradient previewGradient;

  const WallpaperOption({
    required this.name,
    required this.seedColor,
    required this.previewGradient,
  });
}

class DynamicColorPage extends ConsumerStatefulWidget {
  const DynamicColorPage({super.key});

  @override
  ConsumerState<DynamicColorPage> createState() => _DynamicColorPageState();
}

class _DynamicColorPageState extends ConsumerState<DynamicColorPage> {
  final List<WallpaperOption> _wallpapers = const [
    WallpaperOption(
      name: 'Sunset Glow',
      seedColor: Color(0xFFE53935),
      previewGradient: LinearGradient(
        colors: [Color(0xFFFF8A80), Color(0xFFE53935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    WallpaperOption(
      name: 'Teal Zen',
      seedColor: Color(0xFF009688),
      previewGradient: LinearGradient(
        colors: [Color(0xFF80CBC4), Color(0xFF009688)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    WallpaperOption(
      name: 'Ocean Breeze',
      seedColor: Color(0xFF00ACC1),
      previewGradient: LinearGradient(
        colors: [Color(0xFF80DEEA), Color(0xFF00ACC1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    WallpaperOption(
      name: 'Midnight Neon',
      seedColor: Color(0xFF8B5CF6),
      previewGradient: LinearGradient(
        colors: [Color(0xFFC7D2FE), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    WallpaperOption(
      name: 'Desert Dunes',
      seedColor: Color(0xFFFB8C00),
      previewGradient: LinearGradient(
        colors: [Color(0xFFFFCC80), Color(0xFFFB8C00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    WallpaperOption(
      name: 'Deep Forest',
      seedColor: Color(0xFF2E7D32),
      previewGradient: LinearGradient(
        colors: [Color(0xFFA5D6A7), Color(0xFF2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    final currentAccent = themeState.accentColor;
    final r = currentAccent.r * 255;
    final g = currentAccent.g * 255;
    final b = currentAccent.b * 255;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(AppTheme.background, context),
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: 40,
            ),
            children: [
              // 1. M3 Concept Explanation Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: AppTheme.radiusMedium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle_fill,
                            color: themeState.accentColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'User-Generated Source Color',
                            style: AppTheme.title.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Based on Material 3 specifications, this app extracts a key source color and dynamically derives a full, harmonious tonal color scheme. Every background, card, border, and button automatically shifts to match the seed.',
                        style: AppTheme.bodySmall.copyWith(
                          color: CupertinoColors.systemGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Wallpaper Source Grid
              GlassSettingsSection(
                title: 'Wallpaper Sources (Color Extraction)',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _wallpapers.length,
                      itemBuilder: (context, index) {
                        final wp = _wallpapers[index];
                        final isSelected = currentAccent.toARGB32() == wp.seedColor.toARGB32();

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            themeNotifier.setAccentColor(wp.seedColor);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                // Wallpaper Preview
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: wp.previewGradient,
                                  ),
                                ),
                                // Text label
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                    color: CupertinoColors.black.withValues(alpha: 0.6),
                                    child: Text(
                                      wp.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Selected Checkmark
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: CupertinoColors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.checkmark_alt,
                                        size: 14,
                                        color: wp.seedColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // 3. RGB Custom Color Tuner
              GlassSettingsSection(
                title: 'Custom Color Tuner',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RGB Tuning Palette',
                              style: AppTheme.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeState.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${currentAccent.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  color: themeState.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Red Slider
                        _buildRGBRow(
                          label: 'Red',
                          value: r,
                          color: CupertinoColors.systemRed,
                          onChanged: (val) {
                            themeNotifier.setAccentColor(
                              Color.fromARGB(255, val.toInt(), g.toInt(), b.toInt()),
                            );
                          },
                        ),
                        
                        // Green Slider
                        _buildRGBRow(
                          label: 'Green',
                          value: g,
                          color: CupertinoColors.systemGreen,
                          onChanged: (val) {
                            themeNotifier.setAccentColor(
                              Color.fromARGB(255, r.toInt(), val.toInt(), b.toInt()),
                            );
                          },
                        ),
                        
                        // Blue Slider
                        _buildRGBRow(
                          label: 'Blue',
                          value: b,
                          color: CupertinoColors.systemBlue,
                          onChanged: (val) {
                            themeNotifier.setAccentColor(
                              Color.fromARGB(255, r.toInt(), g.toInt(), val.toInt()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const FloatingHeader(
            title: 'Dynamic Theme',
            showBackButton: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRGBRow({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label: ${value.toInt()}',
                style: AppTheme.bodySmall.copyWith(color: CupertinoColors.systemGrey),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CupertinoSlider(
                  value: value,
                  min: 0,
                  max: 255,
                  activeColor: color,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
