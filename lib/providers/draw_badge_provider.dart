import 'package:flutter/material.dart';
import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';

enum DrawShape { freehand, square, rectangle, circle, triangle }

class DrawBadgeProvider extends ChangeNotifier {
  final int rows = 11;
  final int cols = 44;

  List<List<bool>> _drawViewGrid =
      List.generate(11, (_) => List.generate(44, (_) => false));

  final List<List<bool>> _previewGrid =
      List.generate(11, (_) => List.generate(44, (_) => false));

  bool isDrawing = true;
  DrawShape _selectedShape = DrawShape.freehand;
  BadgeAnimation currentAnimation = LeftAnimation();

  List<List<bool>> getDrawViewGrid() {
    // Merge preview + permanent grid
    final combined = List.generate(
        rows,
        (i) => List.generate(cols, (j) {
              return _drawViewGrid[i][j] || _previewGrid[i][j];
            }));
    return combined;
  }

  DrawShape get selectedShape => _selectedShape;
  bool getIsDrawing() => isDrawing;

  void toggleIsDrawing(bool drawing) {
    isDrawing = drawing;
    notifyListeners();
  }

  void setShape(DrawShape shape) {
    _selectedShape = shape;
    notifyListeners();
  }

  void setCell(int row, int col, bool value, {bool preview = false}) {
    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      if (preview) {
        _previewGrid[row][col] = value;
      } else {
        _drawViewGrid[row][col] = value;
      }
    }
  }

  void clearPreviewGrid() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _previewGrid[i][j] = false;
      }
    }
  }

  void commitGridUpdate() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (_previewGrid[i][j]) {
          _drawViewGrid[i][j] = _previewGrid[i][j];
        }
      }
    }
    clearPreviewGrid();
    notifyListeners();
  }

  void resetDrawViewGrid() {
    _drawViewGrid =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    notifyListeners();
  }

  void updateDrawViewGrid(List<List<bool>> badgeData) {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _drawViewGrid[i][j] =
            (j < badgeData[0].length) ? badgeData[i][j] : false;
      }
    }
    notifyListeners();
  }

  GridPosition getGridPosition(Offset position, double cellSize) {
    final row = (position.dy / cellSize).floor();
    final col = (position.dx / cellSize).floor();
    return GridPosition(row, col);
  }
}

class GridPosition {
  final int x;
  final int y;
  GridPosition(this.x, this.y);
}
