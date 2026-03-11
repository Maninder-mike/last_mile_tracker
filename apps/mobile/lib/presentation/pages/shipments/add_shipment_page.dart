import 'package:flutter/cupertino.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:last_mile_tracker/presentation/widgets/entrance_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/providers/supabase_providers.dart';
import 'package:uuid/uuid.dart';

import 'package:last_mile_tracker/presentation/widgets/animated_button.dart';

import 'package:flutter/services.dart';

class AddShipmentPage extends ConsumerStatefulWidget {
  const AddShipmentPage({super.key});

  @override
  ConsumerState<AddShipmentPage> createState() => _AddShipmentPageState();
}

class _AddShipmentPageState extends ConsumerState<AddShipmentPage> {
  final _trackingController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime _eta = DateTime.now().add(const Duration(days: 3));
  bool _isSaving = false;

  @override
  void dispose() {
    _trackingController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _saveShipment() async {
    if (_trackingController.text.isEmpty ||
        _originController.text.isEmpty ||
        _destinationController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Required Fields'),
          content: const Text('Please fill in all shipment details.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final shipment = Shipment(
        id: 'shp_${const Uuid().v4().substring(0, 8)}',
        trackingNumber: _trackingController.text,
        origin: _originController.text,
        destination: _destinationController.text,
        status: ShipmentStatus.inTransit,
        eta: _eta,
        lastUpdate: DateTime.now(),
      );

      await ref.read(supabaseServiceProvider).createShipment(shipment);

      HapticFeedback.vibrate();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create shipment: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(AppTheme.background, context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 240,
              padding: const EdgeInsets.only(top: 6),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _eta,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => _eta = newDateTime);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16),
              child: AnimatedButton.primary(
                onTap: () => Navigator.of(context).pop(),
                label: 'Confirm Date',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                left: AppTheme.s20,
                right: AppTheme.s20,
                bottom: 48.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntranceAnimation(
                        index: 0,
                        child: _SectionHeader(
                          title: 'Shipment Identity',
                          icon: CupertinoIcons.barcode_viewfinder,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.s12),
                      EntranceAnimation(
                        index: 1,
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          opacity: 0.6,
                          child: Column(
                            children: [
                              _InputField(
                                controller: _trackingController,
                                placeholder: 'Enter Tracking Number',
                                icon: CupertinoIcons.tag_fill,
                                label: 'Tracking #',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.s32),
                      EntranceAnimation(
                        index: 2,
                        child: _SectionHeader(
                          title: 'Route Information',
                          icon: CupertinoIcons.map_pin_ellipse,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(height: AppTheme.s12),
                      EntranceAnimation(
                        index: 3,
                        child: GlassContainer(
                          padding: EdgeInsets.zero,
                          opacity: 0.6,
                          child: Column(
                            children: [
                              _InputField(
                                controller: _originController,
                                placeholder: 'Origin City / Hub',
                                icon: CupertinoIcons.house_fill,
                                label: 'Origin',
                              ),
                              const _Divider(),
                              _InputField(
                                controller: _destinationController,
                                placeholder: 'Destination City / Final Hub',
                                icon: CupertinoIcons.location_fill,
                                label: 'Destination',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.s32),
                      EntranceAnimation(
                        index: 4,
                        child: _SectionHeader(
                          title: 'Logistics Timeline',
                          icon: CupertinoIcons.time,
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(height: AppTheme.s12),
                      EntranceAnimation(
                        index: 5,
                        child: GestureDetector(
                          onTap: _showDatePicker,
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.s20,
                              vertical: AppTheme.s16,
                            ),
                            opacity: 0.6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppTheme.s8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoDynamicColor.resolve(
                                          AppTheme.warning,
                                          context,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.calendar,
                                        size: AppTheme.iconSizeSmall,
                                        color: CupertinoDynamicColor.resolve(
                                          AppTheme.warning,
                                          context,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.s12),
                                    Text(
                                      'Estimated Arrival',
                                      style: AppTheme.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.s12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  child: Text(
                                    '${_eta.month}/${_eta.day} @ ${_eta.hour}:${_eta.minute.toString().padLeft(2, '0')}',
                                    style: AppTheme.body.copyWith(
                                      color: CupertinoTheme.of(
                                        context,
                                      ).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: [
                                        const FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 64),
                      EntranceAnimation(
                        index: 6,
                        child: AnimatedButton.primary(
                          onTap: _isSaving ? () {} : _saveShipment,
                          label: _isSaving ? 'CREATING...' : 'CREATE SHIPMENT',
                          icon: _isSaving
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : const Icon(
                                  CupertinoIcons.cube_box_fill,
                                  color: CupertinoColors.white,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.s16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const FloatingHeader(
            title: 'Add Shipment',
            showBackButton: true,
            trailing: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = CupertinoDynamicColor.resolve(color, context);
    return Row(
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: AppTheme.caption.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String label;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.placeholder,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s20,
        vertical: AppTheme.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: CupertinoDynamicColor.resolve(
                  AppTheme.textSecondary,
                  context,
                ).withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: AppTheme.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            placeholderStyle: AppTheme.body.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
            decoration: null,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.s8),
            cursorColor: CupertinoTheme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppTheme.s20),
      height: 0.5,
      color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
    );
  }
}
