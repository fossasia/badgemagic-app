import 'package:badgemagic/badge_animation/ani_cycle.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferCycleAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  final List<List<List<bool>>> frames = CycleAnimation().transferFrames();

  await sendAnimationFrames(
    label: 'Cycle',
    frames: frames,
    transferData: transferData,
  );
}
