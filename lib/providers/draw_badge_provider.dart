import 'package:flutter/material.dart';
import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/animation_abstract.dart';

enum DrawShape { freehand, square, rectangle, circle, triangle }

enum DrawMoveDirection { left, right, up, down }

class DrawBadgeProvider extends ChangeNotifier {
  final int rows = 11;
  final int cols = 44;

  List<List<bool>> _drawViewGrid =
      List.generate(11, (_) => List.generate(44, (_) => false));
  final List<List<bool?>> _previewGrid =
      List.generate(11, (_) => List.generate(44, (_) => null));
  final List<List<List<bool>>> _undoStack = [];
  final List<List<List<bool>>> _redoStack = [];

  bool isDrawing = true;
  DrawShape _selectedShape = DrawShape.freehand;
  BadgeAnimation currentAnimation = LeftAnimation();

  List<List<bool>> getDrawViewGrid() {
    return List.generate(
      rows,
      (i) => List.generate(
        cols,
        (j) {
          final preview = _previewGrid[i][j];
          return preview ?? _drawViewGrid[i][j];
        },
      ),
    );
  }

  DrawShape get selectedShape => _selectedShape;
  bool getIsDrawing() => isDrawing;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

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
        notifyListeners();
      }
    }
  }

  void clearPreviewGrid() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _previewGrid[i][j] = null;
      }
    }
  }

  void commitGridUpdate() {
    _pushToUndoStack();

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (_previewGrid[i][j] != null) {
          _drawViewGrid[i][j] = _previewGrid[i][j]!;
        }
      }
    }

    clearPreviewGrid();
    notifyListeners();
  }

  void resetDrawViewGrid() {
    _pushToUndoStack();
    _drawViewGrid =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    notifyListeners();
  }

  void updateDrawViewGrid(List<List<bool>> badgeData) {
    _pushToUndoStack();
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

  void _pushToUndoStack() {
    _undoStack.add(_copyGrid(_drawViewGrid));
    _redoStack.clear();
  }

  void pushToUndoStack() {
    _pushToUndoStack();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_copyGrid(_drawViewGrid));
      _drawViewGrid = _undoStack.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_copyGrid(_drawViewGrid));
      _drawViewGrid = _redoStack.removeLast();
      notifyListeners();
    }
  }

  /// Shifts the entire committed drawing by one cell with wrap-around.
  /// One call is one undoable action.
  void shiftDrawing(DrawMoveDirection direction) {
    clearPreviewGrid();
    _pushToUndoStack();
    _drawViewGrid = _shiftedGrid(_drawViewGrid, direction);
    notifyListeners();
  }

  List<List<bool>> _shiftedGrid(
    List<List<bool>> grid,
    DrawMoveDirection direction,
  ) {
    final int rowCount = rows;
    final int colCount = cols;
    final List<List<bool>> shifted =
        List.generate(rowCount, (_) => List.filled(colCount, false));

    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        final int sourceRow;
        final int sourceCol;
        switch (direction) {
          case DrawMoveDirection.left:
            sourceRow = row;
            sourceCol = (col + 1) % colCount;
            break;
          case DrawMoveDirection.right:
            sourceRow = row;
            sourceCol = (col - 1 + colCount) % colCount;
            break;
          case DrawMoveDirection.up:
            sourceRow = (row + 1) % rowCount;
            sourceCol = col;
            break;
          case DrawMoveDirection.down:
            sourceRow = (row - 1 + rowCount) % rowCount;
            sourceCol = col;
            break;
        }
        shifted[row][col] = grid[sourceRow][sourceCol];
      }
    }
    return shifted;
  }

  List<List<bool>> _copyGrid(List<List<bool>> grid) {
    return grid.map((row) => List<bool>.from(row)).toList();
  }
}

class GridPosition {
  final int x;
  final int y;

  GridPosition(this.x, this.y);
}
