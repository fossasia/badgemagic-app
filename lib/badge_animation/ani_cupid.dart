import 'dart:math';

import 'package:badgemagic/badge_animation/animation_abstract.dart';

class CupidAnimation extends BadgeAnimation {
  static int frameCount(int bw, int bh) {
    // Logical frame count for smooth animation
    int heartW = 9;
    int heartLeft = bw - heartW - 6;
    int arrowStart = 2 + 2;
    return (heartLeft + heartW + 1) - arrowStart;
  }

  static const int _arrowLen = 11;

  @override
  void processAnimation(
      int bh, int bw, int idx, List<List<bool>> pg, List<List<bool>> c) {
    // Loop idx for continuous animation
    int frameLimit = CupidAnimation.frameCount(bw, bh);
    idx = idx % frameLimit;
    for (int y = 0; y < bh; y++) {
      for (int x = 0; x < bw; x++) {
        c[y][x] = false;
      }
    }

    int heartW = 9;
    int heartH = 8;
    int heartLeft = bw - heartW - 6;
    int heartRight = heartLeft + heartW - 1;
    int heartTop = (bh - heartH) ~/ 2;
    int midY = bh ~/ 2;
    int bowX = 2;
    int arrowStart = bowX + 2;

    _drawBow(c, bowX, midY, (bh - 1) ~/ 2, bw, bh);
    _drawHeart(c, heartLeft + heartW ~/ 2, heartTop + heartH ~/ 2, heartW,
        heartH, bw, bh);

    int arrowX = arrowStart + idx;
    int tailX = arrowX - 1;
    if (tailX >= 0 && tailX < bw && (tailX < heartLeft || tailX > heartRight)) {
      _drawArrowTail(c, arrowX, midY, bw, bh);
    }

    for (int i = 0; i < _arrowLen - 1; i++) {
      int px = arrowX + i;
      if (px >= 0 && px < bw && (px < heartLeft || px > heartRight)) {
        c[midY][px] = true;
      }
    }

    int tipX = arrowX + _arrowLen - 1;
    if (tipX >= 0 && tipX < bw && (tipX < heartLeft || tipX > heartRight)) {
      c[midY][tipX] = true;
      if (midY - 1 >= 0 && tipX - 1 >= 0) c[midY - 1][tipX - 1] = true;
      if (midY + 1 < bh && tipX - 1 >= 0) c[midY + 1][tipX - 1] = true;
    }
  }

  void _drawArrowTail(List<List<bool>> canvas, int x, int y, int w, int h) {
    int tx = x - 1;
    if (tx < 0 || y < 0 || y >= h) return;
    canvas[y][tx] = true;
    if (y - 1 >= 0 && tx - 1 >= 0) canvas[y - 1][tx - 1] = true;
    if (y + 1 < h && tx - 1 >= 0) canvas[y + 1][tx - 1] = true;
  }

  void _drawBow(List<List<bool>> canvas, int x, int cy, int r, int w, int h) {
    for (int y = cy - r; y <= cy + r; y++) {
      if (x >= 0 && x < w && y >= 0 && y < h) canvas[y][x] = true;
    }
    int prev = x;
    for (int dy = -r; dy <= r; dy++) {
      int py = cy + dy;
      double norm = dy / r;
      int px = x + (r * (1 - norm * norm)).round();
      if (px >= 0 && px < w && py >= 0 && py < h) canvas[py][px] = true;
      for (int fx = min(prev, px); fx <= max(prev, px); fx++) {
        if (py >= 0 && py < h && fx >= 0 && fx < w) canvas[py][fx] = true;
      }
      prev = px;
    }
  }

  void _drawHeart(List<List<bool>> canvas, int cx, int cy, int width,
      int height, int w, int h) {
    int n = 60;
    for (int i = 0; i < n; i++) {
      double t = 2 * pi * i / n;
      num xt = 16 * pow(sin(t), 3);
      double yt = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
      int px = cx + (xt * width / 32).round();
      int py = cy - (yt * height / 26).round();
      if (px >= 0 && px < w && py >= 0 && py < h) canvas[py][px] = true;
    }
  }
}
