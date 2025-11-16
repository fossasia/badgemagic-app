import 'package:badgemagic/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LayoutConfig {
  final double padding;
  final double spacing;
  final double iconSize;
  final double cornerRadius;
  final int gridCount;
  final double fontScale;
  final double suffixIconMaxWidth;
  final double itemHeight;
  final double dropdownMaxHeightFactor;
  final double minTabSectionHeight;
  final double imageHeight;
  final double maxContentWidth;

  const LayoutConfig({
    required this.padding,
    required this.spacing,
    required this.iconSize,
    required this.cornerRadius,
    required this.gridCount,
    required this.fontScale,
    required this.suffixIconMaxWidth,
    required this.itemHeight,
    required this.dropdownMaxHeightFactor,
    required this.minTabSectionHeight,
    required this.imageHeight,
    required this.maxContentWidth,
  });
}

LayoutConfig useLayoutConfig(BuildContext context) {
  final settings = Provider.of<AppSettingsProvider>(context);
  final size = settings.selectedSize;

  switch (size) {
    case ScreenSize.S:
      return const LayoutConfig(
        padding: 9, //increasing the padding here 
        spacing: 7,
        iconSize: 20,
        cornerRadius: 8,
        gridCount: 2,
        fontScale: 1.0,
        suffixIconMaxWidth:120,
        itemHeight: 50,
        dropdownMaxHeightFactor: 300,
        minTabSectionHeight: 200,
        imageHeight: 200,
        maxContentWidth: 300,
      );
    case ScreenSize.M:
      return const LayoutConfig(
        padding: 12,
        spacing: 10,
        iconSize: 24,
        cornerRadius: 12,
        gridCount: 3,
        fontScale: 1.1,
        suffixIconMaxWidth:150,
        itemHeight: 58,
        dropdownMaxHeightFactor: 320,
        minTabSectionHeight: 260,
        imageHeight: 240,
        maxContentWidth: 340,
      );
    case ScreenSize.L:
      return const LayoutConfig(
        padding: 16,
        spacing: 14,
        iconSize: 28,
        cornerRadius: 16,
        gridCount: 4,
        fontScale: 1.25,
        suffixIconMaxWidth:180,
        itemHeight: 66,
        dropdownMaxHeightFactor: 340,
        minTabSectionHeight: 320,
        imageHeight: 280,
        maxContentWidth: 380,
      );
    case ScreenSize.XL:
      return const LayoutConfig(
        padding: 20,
        spacing: 18,
        iconSize: 32,
        cornerRadius: 20,
        gridCount: 5,
        fontScale: 1.4,
        suffixIconMaxWidth:210,
        itemHeight: 74,
        dropdownMaxHeightFactor: 360,
        minTabSectionHeight: 380,
        imageHeight: 320,
        maxContentWidth: 420,
      );
  }
}
