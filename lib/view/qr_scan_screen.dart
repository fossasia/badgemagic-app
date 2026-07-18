import 'package:badgemagic/bademagic_module/utils/qr_code_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  AppLocalizations get _l10n => GetIt.instance.get<LocalizationService>().l10n;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    _processCapture(capture);
  }

  bool _processCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final String? raw = barcode.rawValue;
      if (raw == null || !QrCodeHelper.isBadgePayload(raw)) {
        continue;
      }

      final Map<String, dynamic>? badgeJson = QrCodeHelper.decode(raw);
      if (badgeJson == null) {
        ToastUtils().showToast(_l10n.couldNotReadBadgeQr);
        continue;
      }

      _handled = true;
      Navigator.of(context).pop(badgeJson);
      return true;
    }
    return false;
  }

  Future<void> _pickFromGallery() async {
    if (_handled) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      final String? path = result?.files.single.path;
      if (path == null) return;

      final BarcodeCapture? capture = await _controller.analyzeImage(path);
      if (!mounted) return;

      if (capture == null || !_processCapture(capture)) {
        ToastUtils().showToast(_l10n.noBadgeQrInImage);
      }
    } catch (e) {
      ToastUtils().showToast(_l10n.couldNotReadQrFromImage);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanBadgeQrCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: l10n.toggleTorch,
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: l10n.switchCamera,
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.scanQrInstruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(l10n.importFromImage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
