import 'dart:math' as math;

import 'package:badgemagic/bademagic_module/utils/badge_utils.dart';
import 'package:flutter/material.dart';

class BadgePaint extends CustomPainter {
  BadgeUtils badgeUtils = BadgeUtils();
  final List<List<bool>> grid;

  BadgePaint({required this.grid});

  @override
  void paint(Canvas canvas, Size size) {
    // Padding for the rectangle
    MapEntry<double, double> badgeOffsetBackground =
        badgeUtils.getBadgeOffsetBackground(size);
    double offsetHeightBadgeBackground = badgeOffsetBackground.key;
    double offsetWidthBadgeBackground = badgeOffsetBackground.value;

    // Size of the rectangle
    MapEntry<double, double> badgeSize = badgeUtils.getBadgeSize(
        offsetHeightBadgeBackground, offsetWidthBadgeBackground, size);
    double badgeHeight = badgeSize.key;
    double badgeWidth = badgeSize.value;

    // Draw the outer rectangle
    final Paint rectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final RRect gridRect = RRect.fromLTRBR(
      offsetWidthBadgeBackground,
      offsetHeightBadgeBackground,
      offsetWidthBadgeBackground + badgeWidth,
      offsetHeightBadgeBackground + badgeHeight,
      const Radius.circular(10.0),
    );

    canvas.drawRRect(gridRect, rectPaint);

    var cellSize = badgeWidth / grid[0].length;

    MapEntry<double, double> cellStartCoordinate =
        badgeUtils.getCellStartCoordinate(offsetWidthBadgeBackground,
            offsetHeightBadgeBackground, badgeWidth, badgeHeight);
    double cellStartX = cellStartCoordinate.key;
    double cellStartY = cellStartCoordinate.value;
    // Draw the cells
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        var cellStartRow = cellStartY + row * cellSize;
        var cellStartCol = cellStartX + col * (cellSize * 0.93);

        final Paint paint = Paint()
          ..color = grid[row][col] ? Colors.red : Colors.grey.shade900
          ..style = PaintingStyle.fill;

        final Rect cellRect = Rect.fromLTWH(
          cellStartCol,
          cellStartRow,
          cellSize / 2.5,
          cellSize,
        );

        // Apply 45-degree rotation
        canvas.save();
        canvas.translate(
          cellRect.left + (cellRect.width / 2),
          cellRect.top + (cellRect.height / 2),
        );
        canvas.rotate(math.pi / 4);
        canvas.translate(
          -(cellRect.left + (cellRect.width / 2)),
          -(cellRect.top + (cellRect.height / 2)),
        );

        canvas.drawRect(cellRect, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
