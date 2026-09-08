import 'package:badgemagic/badge_animation/ani_emergency.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferEmergencyAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  final generated = List.generate(animationFrameCount, (i) {
    final frameBitmap = blankFrame();
    EmergencyAnimation().processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      i,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  final frames = [
    generated[6],
    generated[7],
    generated[0],
    generated[1],
    generated[2],
    generated[3],
    generated[4],
    generated[5],
  ];

  await sendAnimationFrames(
    label: 'Emergency',
    frames: frames,
    transferData: transferData,
  );
}
