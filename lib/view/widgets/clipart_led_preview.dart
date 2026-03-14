import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';

/// Displays a clipart grid in the same red-LED style as Saved Badges.
class ClipartLedPreview extends StatelessWidget {
  final List<List<int>> grid;

  const ClipartLedPreview({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    if (grid.isEmpty) return const SizedBox.shrink();
    final boolGrid = grid
        .map((row) => row.map((e) => e == 1).toList())
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: size,
          painter: BadgePaint(grid: boolGrid),
        );
      },
    );
  }
}
