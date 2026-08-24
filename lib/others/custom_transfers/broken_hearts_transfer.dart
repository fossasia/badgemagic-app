import 'dart:math';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/custom_transfers/common.dart';

Future<void> customTransferBrokenHeartsAnimation(
  Future<void> Function(DataTransferManager) transferData,
  int speedLevel, {
  bool skipAdapterCheck = false,
}) async {
  final List<List<int>> heartShape = [
    [0, 0, 1, 1, 0, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];
  final int heartW = heartShape[0].length;
  final int heartH = heartShape.length;
  final int leftCx = animationBadgeWidth ~/ 4 - heartW ~/ 2 - 2;
  final int rightCx = 3 * animationBadgeWidth ~/ 4 - heartW ~/ 2 - 2;
  final int topY = animationBadgeHeight ~/ 2 - heartH ~/ 2;
  final Random rng = Random(12345);

  final pixelsL = <Point<int>>[];
  final pixelsR = <Point<int>>[];
  for (int y = 0; y < heartH; y++) {
    for (int x = 0; x < heartW; x++) {
      if (heartShape[y][x] == 1) {
        pixelsL.add(Point(leftCx + x, topY + y));
        pixelsR.add(Point(rightCx + x, topY + y));
      }
    }
  }

  int numClusters = 6;
  int clusterSize = (pixelsL.length / numClusters).ceil();
  List<List<Point<int>>> clustersL = [];
  List<List<Point<int>>> clustersR = [];
  var tempL = List<Point<int>>.from(pixelsL);
  var tempR = List<Point<int>>.from(pixelsR);
  while (tempL.isNotEmpty) {
    int size = min(clusterSize, tempL.length);
    final clusterL = <Point<int>>[];
    final clusterR = <Point<int>>[];
    for (int i = 0; i < size; i++) {
      int idx = rng.nextInt(tempL.length);
      clusterL.add(tempL.removeAt(idx));
      clusterR.add(tempR.removeAt(idx));
    }
    clustersL.add(clusterL);
    clustersR.add(clusterR);
  }
  final paired = List.generate(
    clustersL.length,
    (i) => MapEntry(clustersL[i], clustersR[i]),
  );
  paired.sort((a, b) {
    double ya = a.key.map((p) => p.y).reduce((u, v) => u + v) / a.key.length;
    double yb = b.key.map((p) => p.y).reduce((u, v) => u + v) / b.key.length;
    return yb.compareTo(ya);
  });
  clustersL = paired.map((e) => e.key).toList();
  clustersR = paired.map((e) => e.value).toList();

  final int N = clustersL.length;

  final frames = List.generate(animationFrameCount, (frame) {
    int logicFrame = frame;
    int fallStep = 3;
    final frameBitmap = blankFrame();
    if (frame < animationFrameCount - 1) {
      for (int i = 0; i < N; i++) {
        bool isFalling = logicFrame >= i;
        int dy = (logicFrame - i) * fallStep;
        for (var pt in clustersL[i]) {
          int y = isFalling ? pt.y + dy : pt.y;
          if (y >= 0 && y < animationBadgeHeight) frameBitmap[y][pt.x] = true;
        }
        for (var pt in clustersR[i]) {
          int y = isFalling ? pt.y + dy : pt.y;
          if (y >= 0 && y < animationBadgeHeight) frameBitmap[y][pt.x] = true;
        }
      }
    }
    return frameBitmap;
  });

  await sendAnimationFrames(
    label: 'Broken Hearts',
    frames: frames,
    transferData: transferData,
    skipAdapterCheck: skipAdapterCheck,
  );
}
