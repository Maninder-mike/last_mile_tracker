import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last_mile_tracker/presentation/providers/database_config_provider.dart';
import 'package:last_mile_tracker/core/theme/app_theme.dart';

class CloudConnectionModal extends ConsumerStatefulWidget {
  const CloudConnectionModal({super.key});

  static void show(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const CloudConnectionModal(),
    );
  }

  @override
  ConsumerState<CloudConnectionModal> createState() =>
      _CloudConnectionModalState();
}

class _CloudConnectionModalState extends ConsumerState<CloudConnectionModal> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  bool _isTesting = false;
  String? _errorMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(databaseConfigProvider);
    _urlController = TextEditingController(
      text: currentConfig.isDemoMode
          ? ''
          : currentConfig.url,
    );
    _keyController = TextEditingController(
      text: currentConfig.isDemoMode ? '' : currentConfig.anonKey,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveConnection() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _errorMessage = 'Both URL and Anon Key are required.';
        _testSuccess = false;
      });
      return;
    }

    final parsedUri = Uri.tryParse(url);
    if (parsedUri == null || parsedUri.host.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter a valid URL (e.g., https://your-project.supabase.co).';
        _testSuccess = false;
      });
      return;
    }

    if (!parsedUri.isScheme('https') && !parsedUri.isScheme('http')) {
      setState(() {
        _errorMessage = 'URL scheme must be http:// or https://.';
        _testSuccess = false;
      });
      return;
    }

    if (kReleaseMode && !parsedUri.isScheme('https')) {
      setState(() {
        _errorMessage =
            'Security Policy: Database connections must use secure HTTPS transport in production.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _errorMessage = null;
      _testSuccess = false;
    });

    try {
      // Create temporary client and test fetch
      final tempClient = SupabaseClient(url, key);
      await tempClient.from('shipments').select().limit(1);

      setState(() {
        _testSuccess = true;
        _isTesting = false;
      });

      HapticFeedback.mediumImpact();

      // Wait a short moment to show green success, then save and pop
      await Future.delayed(const Duration(milliseconds: 600));
      await ref.read(databaseConfigProvider.notifier).setConfig(
            url: url,
            anonKey: key,
          );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessBanner();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed: ${e.toString()}';
        _isTesting = false;
        _testSuccess = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _showSuccessBanner() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Connected'),
          ],
        ),
        content: const Text(
          'Successfully connected to your custom Supabase database! Fetching real-time tracking data now.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _switchToDemoMode() async {
    HapticFeedback.selectionClick();
    await ref.read(databaseConfigProvider.notifier).enableDemoMode();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(databaseConfigProvider);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: Container(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cloud Configuration',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.resolvedTextPrimary(context),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Link your local application to your Supabase instance to track actual shipments and log live telemetry.',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.resolvedTextSecondary(context),
                ),
              ),
              const SizedBox(height: 24),

              // URL Input
              Text('SUPABASE URL', style: AppTheme.label),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _urlController,
                placeholder: 'https://your-project.supabase.co',
                keyboardType: TextInputType.url,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x1F2C2C2E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
                  ),
                ),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.resolvedTextPrimary(context),
                ),
              ),
              const SizedBox(height: 16),

              // Key Input
              Text('SUPABASE ANON KEY', style: AppTheme.label),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _keyController,
                placeholder: 'your-supabase-anon-key',
                obscureText: true,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x1F2C2C2E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
                  ),
                ),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.resolvedTextPrimary(context),
                ),
              ),
              const SizedBox(height: 24),

              // Testing & Error State
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: AppTheme.caption.copyWith(color: AppTheme.critical),
                  ),
                ),

              // Action Buttons
              if (_isTesting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CupertinoActivityIndicator(),
                  ),
                )
              else if (_testSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.checkmark_circle, color: AppTheme.success),
                      SizedBox(width: 8),
                      Text(
                        'Success! Saving configurations...',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoButton(
                      color: CupertinoTheme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onPressed: _testAndSaveConnection,
                      child: const Text('Test & Connect Cloud'),
                    ),
                    if (!config.isDemoMode) ...[
                      const SizedBox(height: 12),
                      CupertinoButton(
                        color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        onPressed: _switchToDemoMode,
                        child: Text(
                          'Switch to Demo Sandbox Mode',
                          style: TextStyle(
                            color: AppTheme.resolvedTextPrimary(context),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
