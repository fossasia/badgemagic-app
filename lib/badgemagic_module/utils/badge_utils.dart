import 'package:flutter/material.dart';

class BadgeUtils {
  MapEntry<double, double> getBadgeOffsetBackground(Size size) {
    var paddingPercentage = 5.0;
    var offsetHeightBadgeBackground = (paddingPercentage / 100) * size.height;
    var offsetWidthBadgeBackground = (paddingPercentage / 100) * size.width;
    return MapEntry(offsetHeightBadgeBackground, offsetWidthBadgeBackground);
  }

  MapEntry<double, double> getBadgeSize(double offsetHeightBadgeBackground,
      double offsetWidthBadgeBackground, Size size) {
    var badgeHeight = size.height - (2 * offsetHeightBadgeBackground);
    var badgeWidth = size.width - (2 * offsetWidthBadgeBackground);
    return MapEntry(badgeHeight, badgeWidth);
  }

  MapEntry<double, double> getCellStartCoordinate(
      double offsetWidthBadgeBackground,
      double offsetHeightBadgeBackground,
      double badgeWidth,
      double badgeHeight) {
    {
      var cellSize = badgeWidth / 44;

      // Calculate offsets to center the cells within the rectangle
      double totalCellsWidth = (cellSize * 0.92) * 44;
      double totalCellsHeight = cellSize * 11;

      var cellStartX =
          offsetWidthBadgeBackground + (badgeWidth - totalCellsWidth) / 2;
      var cellStartY =
          offsetHeightBadgeBackground + (badgeHeight - totalCellsHeight) / 2;

      return MapEntry(cellStartX, cellStartY);
    }
  }
}
