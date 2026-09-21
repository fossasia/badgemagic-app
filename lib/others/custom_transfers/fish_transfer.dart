import 'package:badgemagic/badge_animation/ani_fish.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferFishAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel, {
  bool skipAdapterCheck = false,
}) async {
  final int logicalFrameCount = FishAnimation.framesPerCycle;

  final frames = List.generate(animationFrameCount, (i) {
    final int logicalIdx =
        ((i * logicalFrameCount) / animationFrameCount).floor();
    final frameBitmap = blankFrame();
    FishAnimation().processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      logicalIdx,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Fish',
    frames: frames,
    transferData: transferData,
    skipAdapterCheck: skipAdapterCheck,
  );
}
