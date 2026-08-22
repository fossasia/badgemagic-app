import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

class DrawShapeOptionsBar extends StatelessWidget {
  final DrawShape selectedShape;
  final ValueChanged<DrawShape> onSelect;
  final double iconSize;
  final double fontSize;

  const DrawShapeOptionsBar({
    super.key,
    required this.selectedShape,
    required this.onSelect,
    required this.iconSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Semantics(
              label: 'Free',
              child: _shapeCard(DrawShape.freehand, Icons.gesture, l10n.free),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: 'Square',
              child:
                  _shapeCard(DrawShape.square, Icons.crop_square, l10n.square),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: 'Rect',
              child: _shapeCard(DrawShape.rectangle, Icons.rectangle_outlined,
                  l10n.rectangle),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: 'Circle',
              child: _shapeCard(
                  DrawShape.circle, Icons.circle_outlined, l10n.circle),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: 'Triangle',
              child: _shapeCard(
                  DrawShape.triangle, Icons.change_history, l10n.triangle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shapeCard(DrawShape shape, IconData icon, String label) {
    final isSelected = selectedShape == shape;

    return ElevatedButton(
      onPressed: () => onSelect(shape),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? colorOnPrimary : colorOnSurface,
        backgroundColor: isSelected ? colorPrimary : colorSurface,
        elevation: isSelected ? 2 : 1,
        side: BorderSide(color: isSelected ? colorPrimary : colorBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        minimumSize: const Size(55, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize * 0.9),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: fontSize * 0.9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
