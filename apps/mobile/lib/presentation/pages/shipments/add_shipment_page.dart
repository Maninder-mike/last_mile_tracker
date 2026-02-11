import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:last_mile_tracker/core/theme/app_theme.dart';
import 'package:last_mile_tracker/presentation/widgets/glass_container.dart';
import 'package:last_mile_tracker/presentation/widgets/floating_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_tracker/domain/models/shipment.dart';
import 'package:last_mile_tracker/presentation/providers/supabase_providers.dart';
import 'package:uuid/uuid.dart';

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
              onPressed: () => Navigator.pop(context),
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
        height: 250,
        color: CupertinoDynamicColor.resolve(AppTheme.background, context),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _eta,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => _eta = newDateTime);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 88,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SHIPMENT DETAILS', style: AppTheme.caption),
                  const SizedBox(height: 16),
                  GlassContainer(
                    child: Column(
                      children: [
                        _InputField(
                          controller: _trackingController,
                          placeholder: 'Tracking Number',
                          icon: CupertinoIcons.barcode,
                        ),
                        const _Divider(),
                        _InputField(
                          controller: _originController,
                          placeholder: 'Origin City',
                          icon: CupertinoIcons.house,
                        ),
                        const _Divider(),
                        _InputField(
                          controller: _destinationController,
                          placeholder: 'Destination City',
                          icon: CupertinoIcons.location_solid,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('EXPECTED ARRIVAL', style: AppTheme.caption),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showDatePicker,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                color: CupertinoDynamicColor.resolve(
                                  AppTheme.primary,
                                  context,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ETA',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_eta.month}/${_eta.day} ${_eta.hour}:${_eta.minute.toString().padLeft(2, '0')}',
                            style: AppTheme.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _isSaving ? null : _saveShipment,
                      child: _isSaving
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Create Shipment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const FloatingHeader(title: 'Add Shipment', showBackButton: true),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.placeholder,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: CupertinoDynamicColor.resolve(
              AppTheme.primary,
              context,
            ).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: AppTheme.caption,
              style: AppTheme.body,
              decoration: null,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
    );
  }
}
