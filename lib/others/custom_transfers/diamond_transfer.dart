import 'package:badgemagic/badge_animation/ani_diamond.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferDiamondAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  const int spawnInterval = 4;
  final DiamondAnimation diamondAnimation = DiamondAnimation();

  final int maxDy = animationBadgeHeight ~/ 2;
  final int maxDx = animationBadgeWidth ~/ 4;
  final int maxRadius = maxDy > maxDx ? maxDy : maxDx;
  final int cycleLength = spawnInterval * 2 + maxRadius + 1;
  final int startIndex = cycleLength - animationFrameCount;

  final frames = List.generate(animationFrameCount, (frame) {
    final int animationIndex = (startIndex + frame) % cycleLength;
    final frameBitmap = blankFrame();
    diamondAnimation.processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      animationIndex,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Diamond',
    frames: frames,
    transferData: transferData,
  );
}
