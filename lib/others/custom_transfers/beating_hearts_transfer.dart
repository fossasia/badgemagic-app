import 'package:badgemagic/badge_animation/ani_beating_hearts.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferBeatingHeartsAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  final frames = List.generate(animationFrameCount, (i) {
    final frameBitmap = blankFrame();
    BeatingHeartsAnimation().processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      i,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Beating Hearts',
    frames: frames,
    transferData: transferData,
  );
}
