import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badgemagic/bademagic_module/utils/qr_code_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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

class QrShareScreen extends StatefulWidget {
  final String payload;

  const QrShareScreen({super.key, required this.payload});

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        ToastUtils().showToast('Could not generate QR image.');
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/badge_qr.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      ToastUtils().showToast('Could not share QR image.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Share badge QR code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share QR image',
            onPressed: _shareQrImage,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(
                  data: widget.payload,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Scan this code from another device, or tap share to send the '
                'QR image.',
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
