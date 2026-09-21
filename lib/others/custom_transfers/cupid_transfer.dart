import 'package:badgemagic/badge_animation/ani_cupid.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferCupidAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel, {
  bool skipAdapterCheck = false,
}) async {
  final int logicalFrameCount =
      CupidAnimation.frameCount(animationBadgeWidth, animationBadgeHeight);

  final frames = List.generate(animationFrameCount, (i) {
    final int logicalIdx =
        ((i * logicalFrameCount) / animationFrameCount).floor();
    final frameBitmap = blankFrame();
    CupidAnimation().processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      logicalIdx,
      frameBitmap,
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Cupid',
    frames: frames,
    transferData: transferData,
    skipAdapterCheck: skipAdapterCheck,
  );
}
