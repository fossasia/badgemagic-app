import 'package:badgemagic/badge_animation/ani_feet.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferFeetAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  const int badgeHeight = FeetAnimation.badgeHeight;
  const int badgeWidth = FeetAnimation.badgeWidth;
  final feetAnimation = FeetAnimation();

  final List<int> sampledFrames = List.generate(
    animationFrameCount,
    (i) => FeetAnimation.frameCount - animationFrameCount + i,
  );

  final frames = sampledFrames.map((frame) {
    final frameBitmap = blankFrame(badgeHeight, badgeWidth);
    feetAnimation.processAnimation(
      badgeHeight,
      badgeWidth,
      frame,
      blankFrame(badgeHeight, badgeWidth),
      frameBitmap,
    );
    return frameBitmap;
  }).toList();

  await sendAnimationFrames(
    label: 'Feet',
    frames: frames,
    transferData: transferData,
  );
}
