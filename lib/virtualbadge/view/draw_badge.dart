import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';

class BMBadge extends StatefulWidget {
  final void Function(DrawBadgeProvider provider)? providerInit;
  final List<List<bool>>? badgeGrid;

  const BMBadge({super.key, this.providerInit, this.badgeGrid});

  @override
  State<BMBadge> createState() => _BMBadgeState();
}

class _BMBadgeState extends State<BMBadge> {
  final drawProvider = DrawBadgeProvider();
  Offset? dragStart;

  @override
  void initState() {
    super.initState();
    if (widget.providerInit != null) widget.providerInit!(drawProvider);
    if (widget.badgeGrid != null) {
      drawProvider.updateDrawViewGrid(widget.badgeGrid!);
    }
  }

  double get _cellSize => MediaQuery.of(context).size.width / 44;

  Offset _getLocalPosition(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  void _handlePanStart(DragStartDetails details) {
    dragStart = _getLocalPosition(details.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final localPosition = _getLocalPosition(details.globalPosition);
    final shape = drawProvider.selectedShape;

    final start = drawProvider.getGridPosition(dragStart!, _cellSize);
    final end = drawProvider.getGridPosition(localPosition, _cellSize);

    drawProvider.clearPreviewGrid();

    switch (shape) {
      case DrawShape.freehand:
        _drawLine(start.x, start.y, end.x, end.y, preview: false);
        dragStart = localPosition;
        drawProvider.commitGridUpdate();
        break;
      case DrawShape.square:
        int size = ((end.x - start.x).abs() + (end.y - start.y).abs()) ~/ 2;
        _drawSquare(start.x, start.y, size, preview: true);
        break;
      case DrawShape.rectangle:
        int w = (end.y - start.y).abs() ~/ 2;
        int h = (end.x - start.x).abs() ~/ 2;
        _drawRectangle(start.x, start.y, h, w, preview: true);
        break;
      case DrawShape.circle:
        int radius = ((end.x - start.x).abs() + (end.y - start.y).abs()) ~/ 2;
        _drawCircle(start.x, start.y, radius, preview: true);
        break;
      case DrawShape.triangle:
        int height = (end.x - start.x).abs();
        _drawTriangle(start.x, start.y, height, preview: true);
        break;
    }

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    drawProvider.notifyListeners();
  }

  void _handlePanEnd(DragEndDetails details) {
    drawProvider.commitGridUpdate();
    dragStart = null;
  }

  void _drawLine(int r1, int c1, int r2, int c2, {bool preview = false}) {
    int dx = (c2 - c1).abs(), dy = (r2 - r1).abs();
    int sx = c1 < c2 ? 1 : -1;
    int sy = r1 < r2 ? 1 : -1;
    int err = dx - dy, x = c1, y = r1;

    while (true) {
      drawProvider.setCell(y, x, drawProvider.getIsDrawing(), preview: preview);
      if (x == c2 && y == r2) break;
      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
  }

  void _drawSquare(int row, int col, int radius, {bool preview = false}) {
    for (int i = -radius; i <= radius; i++) {
      for (int j = -radius; j <= radius; j++) {
        drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
            preview: preview);
      }
    }
  }

  void _drawRectangle(int row, int col, int h, int w, {bool preview = false}) {
    for (int i = -h; i <= h; i++) {
      for (int j = -w; j <= w; j++) {
        drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
            preview: preview);
      }
    }
  }

  void _drawCircle(int row, int col, int radius, {bool preview = false}) {
    for (int i = -radius; i <= radius; i++) {
      for (int j = -radius; j <= radius; j++) {
        if ((i * i + j * j) <= radius * radius) {
          drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
              preview: preview);
        }
      }
    }
  }

  void _drawTriangle(int row, int col, int height, {bool preview = false}) {
    for (int i = 0; i <= height; i++) {
      for (int j = -i; j <= i; j++) {
        drawProvider.setCell(row + i, col + j, drawProvider.getIsDrawing(),
            preview: preview);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ChangeNotifierProvider.value(
      value: drawProvider,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: AspectRatio(
          aspectRatio: 3.2,
          child: Consumer<DrawBadgeProvider>(
            builder: (_, value, __) => CustomPaint(
              painter: BadgePaint(grid: value.getDrawViewGrid()),
              size: Size(width, width / 3.2),
            ),
          ),
        ),
      ),
    );
  }
}
