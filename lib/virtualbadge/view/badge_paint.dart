import 'dart:math' as math;
import 'package:badgemagic/bademagic_module/utils/badge_utils.dart';
import 'package:flutter/material.dart';

class BadgePaint extends CustomPainter {
  BadgeUtils badgeUtils = BadgeUtils();
  final List<List<bool>> grid;
  final TextStyle? textStyle;
  final String text; 

  BadgePaint({required this.grid, this.textStyle, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    MapEntry<double, double> badgeOffsetBackground =
        badgeUtils.getBadgeOffsetBackground(size);
    double offsetHeightBadgeBackground = badgeOffsetBackground.key;
    double offsetWidthBadgeBackground = badgeOffsetBackground.value;
    MapEntry<double, double> badgeSize = badgeUtils.getBadgeSize(
        offsetHeightBadgeBackground, offsetWidthBadgeBackground, size);
    double badgeHeight = badgeSize.key * 1.28;
    double badgeWidth = badgeSize.value + 10;


    double horizontalPadding = 8.0; 
    badgeWidth -= 1.0 * horizontalPadding;
    final Paint rectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final RRect gridRect = RRect.fromLTRBR(
      offsetWidthBadgeBackground + horizontalPadding - 10,
      offsetHeightBadgeBackground,
      offsetWidthBadgeBackground + badgeWidth + horizontalPadding,
      offsetHeightBadgeBackground + badgeHeight,
      const Radius.circular(10.0),
    );

    canvas.drawRRect(gridRect, rectPaint);

    double totalHorizontalPadding = 15.0; 
    double totalVerticalPadding = 10.0; 
    double cellStartX = offsetWidthBadgeBackground + totalHorizontalPadding + 6;
    double cellStartY = offsetHeightBadgeBackground + totalVerticalPadding;

    double cellSize =
        (badgeWidth - 2 * totalHorizontalPadding) / grid[0].length;
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        var cellStartRow = cellStartY + row * cellSize;
        var cellStartCol = cellStartX + col * cellSize;

        final Paint paint = Paint()
          ..color = grid[row][col]
              ? const Color.fromARGB(255, 170, 38, 38)
              : Colors.grey.shade900
          ..style = PaintingStyle.fill;

        final Rect cellRect = Rect.fromLTWH(
          cellStartCol,
          cellStartRow,
          cellSize,
          cellSize,
        );

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
    if (textStyle != null && text.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        offsetWidthBadgeBackground +
            (badgeWidth - textPainter.width) / 2 +
            horizontalPadding,
        offsetHeightBadgeBackground + (badgeHeight - textPainter.height) / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
