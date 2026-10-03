import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/draw_tool_button.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class DrawMoveOptionsBar extends StatelessWidget {
  final DrawBadgeProvider provider;
  final double iconSize;
  final double fontSize;

  const DrawMoveOptionsBar({
    super.key,
    required this.provider,
    required this.iconSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: DrawToolButton(
              icon: Icons.arrow_back,
              label: l10n.moveLeft,
              tint: colorOnSurface,
              iconSize: iconSize,
              fontSize: fontSize,
              onPressed: () => provider.shiftDrawing(DrawMoveDirection.left),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DrawToolButton(
              icon: Icons.arrow_forward,
              label: l10n.moveRight,
              tint: colorOnSurface,
              iconSize: iconSize,
              fontSize: fontSize,
              onPressed: () => provider.shiftDrawing(DrawMoveDirection.right),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DrawToolButton(
              icon: Icons.arrow_upward,
              label: l10n.moveUp,
              tint: colorOnSurface,
              iconSize: iconSize,
              fontSize: fontSize,
              onPressed: () => provider.shiftDrawing(DrawMoveDirection.up),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DrawToolButton(
              icon: Icons.arrow_downward,
              label: l10n.moveDown,
              tint: colorOnSurface,
              iconSize: iconSize,
              fontSize: fontSize,
              onPressed: () => provider.shiftDrawing(DrawMoveDirection.down),
            ),
          ),
        ],
      ),
    );
  }
}
