import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/mode.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';

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
  // Live badge sync
  bool _liveSync = false;
  DateTime _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int minSyncIntervalMs = 100; // 10 FPS max

  void setLiveSync(bool value) {
    _liveSync = value;
    notifyListeners();
  }
  bool get liveSync => _liveSync;

  bool isPaused = false;

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

  void pause() {
    if (!isPaused && !isGameOver) {
      isPaused = true;
      _timer?.cancel();
      notifyListeners();
    }
  }

  void resume() {
    if (isPaused && !isGameOver) {
      isPaused = false;
      _timer = Timer.periodic(Duration(milliseconds: tickMillis), (_) => tick());
      notifyListeners();
    }
  }

  void reset() {
    grid = List.generate(badgeRows, (_) => List.filled(badgeCols, 0));
    score = 0;
    isGameOver = false;
    isPaused = false;
    _timer?.cancel();
    _spawnNewShape();
    _timer = Timer.periodic(Duration(milliseconds: tickMillis), (_) => tick());
    notifyListeners();
  }

  void tick() {
    if (isGameOver || isPaused) return;
    if (!_moveShape(1, 0)) {
      _mergeShapeToGrid();
      _clearLines();
      if (!_spawnNewShape()) {
        isGameOver = true;
        _timer?.cancel();
      }
    }
    if (_liveSync) {
      final now = DateTime.now();
      if (now.difference(_lastSyncTime).inMilliseconds >= minSyncIntervalMs) {
        _lastSyncTime = now;
        _sendGridToBadge();
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
        if (rr < 0 || rr >= badgeRows || cc < 0 || cc >= badgeCols) {
          return false;
        }
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
      if (_liveSync) _maybeSendGridToBadge();
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
      if (_liveSync) _maybeSendGridToBadge();
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
    if (_liveSync) _maybeSendGridToBadge();
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

  void _maybeSendGridToBadge() {
    final now = DateTime.now();
    if (now.difference(_lastSyncTime).inMilliseconds >= minSyncIntervalMs) {
      _lastSyncTime = now;
      _sendGridToBadge();
    }
  }

  Future<void> _sendGridToBadge() async {
    try {
      // Use displayGrid to include falling piece
      List<List<int>> badgeGrid = displayGrid;
      List<String> hex = Converters.convertBitmapToLEDHex(badgeGrid, true);
      Message msg = Message(text: hex, flash: false, marquee: false, speed: Speed.one, mode: Mode.picture);
      Data data = Data(messages: [msg]);
      DataTransferManager manager = DataTransferManager(data);
      await BadgeMessageProvider().transferData(manager);
      // Optionally: ToastUtils().showToast('Live badge updated');
    } catch (e) {
      ToastUtils().showErrorToast('Live badge update failed');
    }
  }

  // Toggle live sync
  void toggleLiveSync() {
    _liveSync = !_liveSync;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}