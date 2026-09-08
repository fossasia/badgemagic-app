import 'package:badgemagic/badge_animation/ani_fireworks.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferFireworksAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  final frames = List.generate(animationFrameCount, (i) {
    final frameBitmap = blankFrame();
    FireworksAnimation().processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      i,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Fireworks',
    frames: frames,
    transferData: transferData,
  );
}
