import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Badge grid size
const int badgeRows = 11;
const int badgeCols = 44;

// Tetromino shapes
final List<List<List<int>>> tetrominoShapes = [
  // I
  [
    [1, 1, 1, 1]
  ],
  // O
  [
    [1, 1],
    [1, 1]
  ],
  // T
  [
    [0, 1, 0],
    [1, 1, 1]
  ],
  // L
  [
    [1, 0],
    [1, 0],
    [1, 1]
  ],
  // J
  [
    [0, 1],
    [0, 1],
    [1, 1]
  ],
  // S
  [
    [0, 1, 1],
    [1, 1, 0]
  ],
  // Z
  [
    [1, 1, 0],
    [0, 1, 1]
  ],
];

class TetrisGameProvider extends ChangeNotifier {
  List<List<int>> grid =
      List.generate(badgeRows, (_) => List.filled(badgeCols, 0));
  int score = 0;
  bool isGameOver = false;
  int currentShapeIndex = 0;
  List<List<int>> currentShape = [];
  int shapeRow = 0;
  int shapeCol = 0;
  Timer? _timer;
  static const int tickMillis = 400;
  Random random = Random();

  TetrisGameProvider() {
    _spawnNewShape();
    _timer = Timer.periodic(Duration(milliseconds: tickMillis), (_) => tick());
  }

  void tick() {
    if (isGameOver) return;
    if (!_moveShape(1, 0)) {
      _mergeShapeToGrid();
      _clearLines();
      if (!_spawnNewShape()) {
        isGameOver = true;
        _timer?.cancel();
      }
    }
    notifyListeners();
  }

  bool _spawnNewShape() {
    currentShapeIndex = random.nextInt(tetrominoShapes.length);
    currentShape = tetrominoShapes[currentShapeIndex]
        .map((row) => List<int>.from(row))
        .toList();
    shapeRow = 0;
    shapeCol = badgeCols ~/ 2 - currentShape[0].length ~/ 2;
    if (!_canPlace(currentShape, shapeRow, shapeCol)) {
      return false;
    }
    return true;
  }

  bool _canPlace(List<List<int>> shape, int r, int c) {
    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape[i].length; j++) {
        if (shape[i][j] == 0) continue;
        int rr = r + i;
        int cc = c + j;
        if (rr < 0 || rr >= badgeRows || cc < 0 || cc >= badgeCols)
          return false;
        if (grid[rr][cc] != 0) return false;
      }
    }
    return true;
  }

  void _mergeShapeToGrid() {
    for (int i = 0; i < currentShape.length; i++) {
      for (int j = 0; j < currentShape[i].length; j++) {
        if (currentShape[i][j] == 1) {
          int rr = shapeRow + i;
          int cc = shapeCol + j;
          if (rr >= 0 && rr < badgeRows && cc >= 0 && cc < badgeCols) {
            grid[rr][cc] = 1;
          }
        }
      }
    }
  }

  void _clearLines() {
    for (int r = badgeRows - 1; r >= 0; r--) {
      if (grid[r].every((cell) => cell == 1)) {
        grid.removeAt(r);
        grid.insert(0, List.filled(badgeCols, 0));
        score++;
        r++; // Check same row again
      }
    }
  }

  bool _moveShape(int dr, int dc) {
    int newRow = shapeRow + dr;
    int newCol = shapeCol + dc;
    if (_canPlace(currentShape, newRow, newCol)) {
      shapeRow = newRow;
      shapeCol = newCol;
      return true;
    }
    return false;
  }

  void moveLeft() {
    if (!isGameOver) {
      _moveShape(0, -1);
      notifyListeners();
    }
  }

  void moveRight() {
    if (!isGameOver) {
      _moveShape(0, 1);
      notifyListeners();
    }
  }

  void rotate() {
    if (isGameOver) return;
    List<List<int>> rotated = _rotateMatrix(currentShape);
    if (_canPlace(rotated, shapeRow, shapeCol)) {
      currentShape = rotated;
      notifyListeners();
    }
  }

  List<List<int>> _rotateMatrix(List<List<int>> mat) {
    final n = mat.length;
    final m = mat[0].length;
    List<List<int>> res = List.generate(m, (_) => List.filled(n, 0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        res[j][n - i - 1] = mat[i][j];
      }
    }
    return res;
  }

  void drop() {
    if (isGameOver) return;
    while (_moveShape(1, 0)) {}
    tick();
    notifyListeners();
  }

  void restart() {
    grid = List.generate(badgeRows, (_) => List.filled(badgeCols, 0));
    score = 0;
    isGameOver = false;
    _timer?.cancel();
    _spawnNewShape();
    _timer = Timer.periodic(Duration(milliseconds: tickMillis), (_) => tick());
    notifyListeners();
  }

  List<List<int>> get displayGrid {
    // Overlay current shape on grid for display
    List<List<int>> tempGrid = grid.map((row) => List<int>.from(row)).toList();
    for (int i = 0; i < currentShape.length; i++) {
      for (int j = 0; j < currentShape[i].length; j++) {
        if (currentShape[i][j] == 1) {
          int rr = shapeRow + i;
          int cc = shapeCol + j;
          if (rr >= 0 && rr < badgeRows && cc >= 0 && cc < badgeCols) {
            tempGrid[rr][cc] = 2;
          }
        }
      }
    }
    return tempGrid;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}