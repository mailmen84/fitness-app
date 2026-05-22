import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/barcode_flow_controller.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isHandlingDetection = false;
  String? _lastErrorMessage;

  // Cooldown between detection attempts so the user can frame the barcode
  // without the scanner firing on a half-captured image. 800ms strikes a
  // balance between responsiveness and "give me a moment to aim".
  static const Duration _detectionCooldown = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      // noDuplicates + a long detectionTimeout ensures the scanner doesn't
      // hammer the same frames over and over while the user aims. Each
      // detection attempt is followed by a quiet period.
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: _detectionCooldown.inMilliseconds,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
      ],
    );
    // Reset previous result so we don't auto-route based on a stale one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(barcodeFlowControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandlingDetection) return;
    String? code;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        code = v;
        break;
      }
    }
    if (code == null) return;

    _isHandlingDetection = true;
    await _scannerController.stop();
    if (!mounted) return;

    await _processBarcode(code);
  }

  Future<void> _processBarcode(String barcode) async {
    final controller = ref.read(barcodeFlowControllerProvider.notifier);
    final result = await controller.lookup(barcode);
    if (!mounted) return;

    switch (result.kind) {
      case BarcodeLookupKind.foundLocal:
        final food = result.localFood;
        if (food != null) {
          context.go(AppRoutePaths.addFoodDetail(food.id));
        }
        return;
      case BarcodeLookupKind.foundOpenFoodFacts:
      case BarcodeLookupKind.notFound:
        context.go('${AppRoutePaths.addScanReview}/${result.barcode!}');
        return;
      case BarcodeLookupKind.error:
        setState(() {
          _lastErrorMessage = result.errorMessage ?? 'Lookup failed.';
          _isHandlingDetection = false;
        });
        await _scannerController.start();
        return;
      case BarcodeLookupKind.idle:
      case BarcodeLookupKind.loading:
        return;
    }
  }

  Future<void> _enterManually() async {
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ManualBarcodeDialog(),
    );
    if (entered == null || entered.trim().isEmpty || !mounted) return;
    await _scannerController.stop();
    await _processBarcode(entered.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final lookupState = ref.watch(barcodeFlowControllerProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan barcode',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Point the camera at a product barcode. We look it up locally first, '
            'then in OpenFoodFacts.',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppSecondaryButton(
            label: 'Back to add hub',
            onPressed: () => context.go(AppRoutePaths.add),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                          errorBuilder: (context, error, _) {
                            return _ScannerErrorView(
                              message: error.errorDetails?.message ??
                                  'Camera unavailable. Use manual entry instead.',
                            );
                          },
                        ),
                        const IgnorePointer(child: _ScannerOverlay()),
                        if (lookupState.kind == BarcodeLookupKind.loading)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x88000000),
                              child: Center(
                                child: AppLoadingBlock(
                                  title: 'Looking up barcode',
                                  message:
                                      'Checking local DB and OpenFoodFacts.',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Torch',
                        onPressed: () => _scannerController.toggleTorch(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Switch camera',
                        onPressed: () => _scannerController.switchCamera(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'Enter barcode manually',
                  expand: true,
                  onPressed: _enterManually,
                ),
              ],
            ),
          ),
          if (_lastErrorMessage != null) ...[
            SizedBox(height: tokens.sectionSpacing),
            AppErrorBlock(
              title: 'Lookup failed',
              message: _lastErrorMessage!,
              action: AppPrimaryButton(
                label: 'Try again',
                expand: true,
                onPressed: () {
                  setState(() => _lastErrorMessage = null);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ManualBarcodeDialog extends StatefulWidget {
  const _ManualBarcodeDialog();

  @override
  State<_ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<_ManualBarcodeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter a barcode value.');
      return;
    }
    if (value.length < 6 || value.length > 32) {
      setState(() => _error = 'Barcode must be 6 to 32 characters.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter barcode manually'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Barcode',
          hintText: 'e.g. 5901234123457',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Look up'),
        ),
      ],
    );
  }
}
