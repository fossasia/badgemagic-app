import 'package:badgemagic/bademagic_module/utils/qr_code_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows a dialog containing a QR code that encodes [badgeJson] so another
/// device can scan and import the badge. Falls back to a toast if the badge is
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

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: const Text(
          'Scan to import badge',
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.dg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 240.w,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Open Badge Magic on another device and scan this code from the import menu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
