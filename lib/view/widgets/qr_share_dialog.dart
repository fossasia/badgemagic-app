import 'package:badgemagic/bademagic_module/utils/qr_code_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Encodes [badgeJson] and opens a full-screen page showing the QR code so
/// another device can scan and import the badge. Shows a toast if the badge is
/// too large to fit in a single QR code.
Future<void> showBadgeQrDialog(
  BuildContext context,
  Map<String, dynamic> badgeJson,
) async {
  final String? payload = QrCodeHelper.encode(badgeJson);

  if (payload == null) {
    ToastUtils().showToast(
      'This badge is too large to share as a QR code. Use file sharing instead.',
    );
    return;
  }

  if (!context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => QrShareScreen(payload: payload),
    ),
  );
}

/// Full-screen page that renders [payload] as a scannable QR code.
class QrShareScreen extends StatelessWidget {
  final String payload;

  const QrShareScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Share badge QR code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Open Badge Magic on another device and scan this code from '
                'the import menu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
