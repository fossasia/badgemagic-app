import 'package:badgemagic/badge_animation/ani_diagonal.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferDiagonalAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel, {
  bool skipAdapterCheck = false,
}) async {
  const int densestFrameIdx = 38;

  final frames = List.generate(animationFrameCount, (i) {
    final frameBitmap = blankFrame();
    DiagonalAnimation().processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      densestFrameIdx + i,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Diagonal',
    frames: frames,
    transferData: transferData,
    skipAdapterCheck: skipAdapterCheck,
  );
}
