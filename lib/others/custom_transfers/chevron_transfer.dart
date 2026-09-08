import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferChevronAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel,
) async {
  const int arrowWidth = 4;
  const int arrowHeight = 7;
  const List<List<bool>> arrow = [
    [false, false, false, true],
    [false, false, true, false],
    [false, true, false, false],
    [true, false, false, false],
    [false, true, false, false],
    [false, false, true, false],
    [false, false, false, true],
  ];

  final frames = List.generate(animationFrameCount, (frame) {
    final frameBitmap = blankFrame();
    final int offset = frame % arrowWidth;
    final int arrowTop = (animationBadgeHeight - arrowHeight) ~/ 2;
    for (int arrowIdx = 0;
        arrowIdx < (animationBadgeWidth / arrowWidth).ceil() + 2;
        arrowIdx++) {
      final int startCol = animationBadgeWidth - offset - arrowIdx * arrowWidth;
      for (int y = 0; y < arrowHeight; y++) {
        for (int x = 0; x < arrowWidth; x++) {
          final int row = arrowTop + y;
          final int col = startCol + x;
          if (row >= 0 &&
              row < animationBadgeHeight &&
              col >= 0 &&
              col < animationBadgeWidth &&
              arrow[y][x]) {
            frameBitmap[row][col] = true;
          }
        }
      }
    }
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Chevron',
    frames: frames,
    transferData: transferData,
  );
}
