import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BMBadge extends StatefulWidget {
  final void Function(DrawBadgeProvider provider)? providerInit;
  final List<List<bool>>? badgeGrid;
  const BMBadge({super.key, this.providerInit, this.badgeGrid});

  @override
  State<BMBadge> createState() => _BMBadgeState();
}

class _BMBadgeState extends State<BMBadge> {
  var drawProvider = DrawBadgeProvider();

  @override
  void initState() {
    if (widget.providerInit != null) {
      widget.providerInit!(drawProvider);
    }
    if (widget.badgeGrid != null) {
      drawProvider.updateDrawViewGrid(widget.badgeGrid!);
    }
    super.initState();
  }

  static const int rows = 11;
  static const int cols = 44;

  void _handlePanUpdate(DragUpdateDetails details) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    double cellWidth = renderBox.size.width / cols;
    double cellHeight = renderBox.size.height / rows;

    int col = (localPosition.dx / cellWidth).clamp(0, cols - 1).toInt();
    int row = (localPosition.dy / cellHeight).clamp(0, rows - 1).toInt();

    setState(() {
      drawProvider.setDrawViewGrid(row, col);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => drawProvider,
      child: GestureDetector(
          onPanUpdate: _handlePanUpdate,
          child: Consumer<DrawBadgeProvider>(
            builder: (context, value, child) => CustomPaint(
              size: const Size(400, 480),
              painter: DrawBadgePaint(grid: value.getDrawViewGrid()),
            ),
          )),
    );
  }
}
