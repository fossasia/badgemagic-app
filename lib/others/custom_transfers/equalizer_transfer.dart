import 'package:badgemagic/badge_animation/ani_equalizer.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferEqualizerAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel, {
  bool skipAdapterCheck = false,
}) async {
  final equalizerAnimation = EqualizerAnimation();

  final frames = List.generate(animationFrameCount, (i) {
    final frameBitmap = blankFrame();
    equalizerAnimation.processAnimation(
      animationBadgeHeight,
      animationBadgeWidth,
      i,
      blankFrame(),
      frameBitmap,
    );
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Equalizer',
    frames: frames,
    transferData: transferData,
    skipAdapterCheck: skipAdapterCheck,
  );
}
