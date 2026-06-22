import 'package:badgemagic/bademagic_module/utils/qr_code_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

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
        ToastUtils().showToast('Could not read this badge QR code.');
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
        ToastUtils().showToast(
          'No badge QR code found in that image.',
        );
      }
    } catch (e) {
      ToastUtils().showToast('Could not read QR code from that image.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan badge QR code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Import QR from image',
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch camera',
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
                const Text(
                  'Point the camera at a badge QR code shared from another '
                  'device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Import from image'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
