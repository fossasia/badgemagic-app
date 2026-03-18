import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:badgemagic/bademagic_module/utils/badge_utils.dart';

class BMBadge extends StatefulWidget {
  final void Function(DrawBadgeProvider provider)? providerInit;
  final List<List<bool>>? badgeGrid;

  const BMBadge({super.key, this.providerInit, this.badgeGrid});

  @override
  State<BMBadge> createState() => _BMBadgeState();
}

class _BMBadgeState extends State<BMBadge> {
  final drawProvider = DrawBadgeProvider();
  final badgeUtils = BadgeUtils();

  final GlobalKey _gestureKey = GlobalKey(); // ✅ KEY FIX

  Offset? dragStart;

  // Badge dimensions
  static const Size _badgeSize = Size(400, 100);
  static const int gridWidth = 44;
  static const int gridHeight = 11;

  @override
  void initState() {
    super.initState();
    if (widget.providerInit != null) widget.providerInit!(drawProvider);
    if (widget.badgeGrid != null) {
      drawProvider.updateDrawViewGrid(widget.badgeGrid!);
    }
  }

RenderBox? get _renderBox =>
      _gestureKey.currentContext?.findRenderObject() as RenderBox?;

Size _getBadgeRenderSize() {
  return _renderBox?.size ?? Size.zero;
}

Offset _getLocalPosition(Offset globalPosition) {
  return _renderBox?.globalToLocal(globalPosition) ?? Offset.zero;
}
  // Convert local position to grid coordinates accounting for badge rendering
({int x, int y}) _localToGrid(Offset localPosition) {
  final size = _getBadgeRenderSize();
  if (size == Size.zero) return (x: -1, y: -1);

  // ===== SAME LOGIC AS PAINTER =====
  final badgeOffsetBackground =
      badgeUtils.getBadgeOffsetBackground(size);

  final offsetY = badgeOffsetBackground.key;
  final offsetX = badgeOffsetBackground.value;

  final badgeSize =
      badgeUtils.getBadgeSize(offsetY, offsetX, size);

  final badgeHeight = badgeSize.key;
  final badgeWidth = badgeSize.value;

  final cellStart = badgeUtils.getCellStartCoordinate(
    offsetX,
    offsetY,
    badgeWidth,
    badgeHeight,
  );

  final cellStartX = cellStart.key;
  final cellStartY = cellStart.value;

  final cellSize = badgeWidth / gridWidth;

  // ===== REMOVE OFFSET =====
  final dx = localPosition.dx - cellStartX;
  final dy = localPosition.dy - cellStartY;

  // ===== HANDLE OUTSIDE AREA =====
  if (dx < 0 || dy < 0) return (x: -1, y: -1);

  // ===== APPLY SAME SCALING AS PAINTER =====
  final col = (dx / (cellSize * 0.93))
      .floor()
      .clamp(0, gridWidth - 1);

  final row = (dy / cellSize)
      .floor()
      .clamp(0, gridHeight - 1);

  return (x: row, y: col);
}
  void _handlePanStart(DragStartDetails details) {
    dragStart =_getLocalPosition(details.globalPosition);

    drawProvider.pushToUndoStack();
    if (drawProvider.selectedShape == DrawShape.freehand && dragStart != null) {
      final gridPos = _localToGrid(dragStart!);
      drawProvider.setCell(gridPos.x, gridPos.y, drawProvider.getIsDrawing(),
          preview: false);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final localPosition = _getLocalPosition(details.globalPosition);
    if (dragStart == null) return;

    final shape = drawProvider.selectedShape;

    final start = _localToGrid(dragStart!);
    final end = _localToGrid(localPosition);

    drawProvider.clearPreviewGrid();

    switch (shape) {
      case DrawShape.freehand:
        _drawLine(start.x, start.y, end.x, end.y, preview: false);
        dragStart = localPosition; // update for next stroke segment
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
  }

  void _handlePanEnd(DragEndDetails details) {
    if (drawProvider.selectedShape != DrawShape.freehand) {
      drawProvider.commitGridUpdate();
    }
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
  void dispose() {
    // This is the "Safety Catch" that stops the memory leak
    drawProvider.dispose(); 
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  return ChangeNotifierProvider.value(
    value: drawProvider,
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _badgeSize.width,
          height: _badgeSize.height,
          child: GestureDetector(
            key:_gestureKey, // Wrapped directly around the drawing area
            behavior: HitTestBehavior.opaque,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: Consumer<DrawBadgeProvider>(
              builder: (_, value, __) => CustomPaint(
                painter: BadgePaint(grid: value.getDrawViewGrid()),
                size: _badgeSize,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}