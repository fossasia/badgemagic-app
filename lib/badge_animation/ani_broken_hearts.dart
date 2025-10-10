import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'dart:math';

class BrokenHeartsAnimation extends BadgeAnimation {
  /// **Now a 9×9 heart** (instead of 7×7), so it fills more of the 11×44 badge.
  static const List<List<int>> heartShape = [
    [0, 0, 1, 1, 0, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 1, 0, 0, 0, 0],
    [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    ], // tip row (optional—it ensures the very bottom pixel sits one row above the badge bottom)
  ];

  final List<List<Point<int>>> _clustersLeft = [];
  final List<List<Point<int>>> _clustersRight = [];
  bool _initialized = false;
  final Random _rng = Random(12345);

  void _initializeClusters(int badgeH, int badgeW) {
    if (_initialized) return;
    _initialized = true;

    final int heartW = heartShape[0].length;
    final int heartH = heartShape.length;
    final int leftCx = badgeW ~/ 4 - heartW ~/ 2;
    final int topY = badgeH ~/ 2 - heartH ~/ 2;

    // collect all solid pixels of left heart
    final pixels = <Point<int>>[];
    for (int y = 0; y < heartH; y++) {
      for (int x = 0; x < heartW; x++) {
        if (heartShape[y][x] == 1) {
          pixels.add(Point(leftCx + x, topY + y));
        }
      }
    }

    // carve into random clusters of size 1–4
    while (pixels.isNotEmpty) {
      int size = _rng.nextInt(min(4, pixels.length)) + 1;
      final clusterL = <Point<int>>[];
      for (int i = 0; i < size; i++) {
        clusterL.add(pixels.removeAt(_rng.nextInt(pixels.length)));
      }
      _clustersLeft.add(clusterL);
      _clustersRight
          .add(clusterL.map((pt) => Point(pt.x + badgeW ~/ 2, pt.y)).toList());
    }

    // sort so bottom-most clusters fall first
    final paired = List.generate(
      _clustersLeft.length,
      (i) => MapEntry(_clustersLeft[i], _clustersRight[i]),
    );
    paired.sort((a, b) {
      double ya = a.key.map((p) => p.y).reduce((u, v) => u + v) / a.key.length;
      double yb = b.key.map((p) => p.y).reduce((u, v) => u + v) / b.key.length;
      return yb.compareTo(ya); // descending: larger Y first
    });
    _clustersLeft
      ..clear()
      ..addAll(paired.map((e) => e.key));
    _clustersRight
      ..clear()
      ..addAll(paired.map((e) => e.value));
  }

  @override
  void processAnimation(
    int badgeHeight,
    int badgeWidth,
    int animationIndex,
    List<List<bool>> processGrid,
    List<List<bool>> canvas,
  ) {
    _initializeClusters(badgeHeight, badgeWidth);

    // clear
    for (int y = 0; y < badgeHeight; y++) {
      for (int x = 0; x < badgeWidth; x++) {
        canvas[y][x] = false;
      }
    }

    final int N = _clustersLeft.length;
    final int cycle = N + badgeHeight;
    final int frame = animationIndex % cycle;

    // draw each cluster either “attached” or “falling”
    for (int i = 0; i < N; i++) {
      final bool isFalling = frame >= i;
      final int dy = frame - i;
      for (var pt in _clustersLeft[i]) {
        final int y = isFalling ? pt.y + dy : pt.y;
        if (y >= 0 && y < badgeHeight) canvas[y][pt.x] = true;
      }
      for (var pt in _clustersRight[i]) {
        final int y = isFalling ? pt.y + dy : pt.y;
        if (y >= 0 && y < badgeHeight) canvas[y][pt.x] = true;
      }
    }
  }
}
