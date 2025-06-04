import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// Direction enum for snake movement
enum Direction { up, down, left, right }

// Position class to represent coordinates
class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class SnakeGameProvider extends ChangeNotifier {
  // Badge dimensions
  static const int rows = 11;
  static const int cols = 44;

  // Game state
  bool _isGameRunning = false;
  bool _isGameOver = false;
  int _score = 0;
  Direction _direction = Direction.right;
  Timer? _gameTimer;

  // Game speed (milliseconds between moves - lower is faster)
  int _gameSpeed = 300;
  static const int minSpeed = 100; // Fastest speed (100ms)
  static const int maxSpeed = 500; // Slowest speed (500ms)
  static const int speedStep = 50; // Speed increment/decrement step

  // Snake body positions (list of coordinates)
  List<Position> _snake = [];

  // Food position
  Position? _food;

  // Grid representation of the badge
  List<List<bool>> _gameGrid =
      List.generate(rows, (i) => List.generate(cols, (j) => false));

  // Getters
  List<List<bool>> get gameGrid => _gameGrid;
  bool get isGameRunning => _isGameRunning;
  bool get isGameOver => _isGameOver;
  int get score => _score;
  int get gameSpeed => _gameSpeed;

  // Calculate speed percentage (0-100%)
  int get speedPercentage =>
      ((maxSpeed - _gameSpeed) * 100 ~/ (maxSpeed - minSpeed)).clamp(0, 100);

  // Initialize the game
  void initGame() {
    // Clear the grid
    _gameGrid = List.generate(rows, (i) => List.generate(cols, (j) => false));

    // Reset score
    _score = 0;

    // Reset direction
    _direction = Direction.right;

    // Reset snake position (start with 3 segments)
    _snake = [
      Position(2, 2), // Head
      Position(2, 1),
      Position(2, 0),
    ];

    // Generate initial food
    _generateFood();

    // Update the grid
    _updateGrid();

    // Cancel any existing timer
    _gameTimer?.cancel();
    _gameTimer = null;

    // Reset game state
    _isGameRunning = false;
    _isGameOver = false;

    notifyListeners();
  }

  // Start the game
  void startGame() {
    if (!_isGameRunning) {
      _isGameRunning = true;

      // Start the game loop with current speed
      _gameTimer = Timer.periodic(Duration(milliseconds: _gameSpeed), (timer) {
        _moveSnake();
      });

      notifyListeners();
    }
  }

  // Increase snake speed
  void increaseSpeed() {
    if (_gameSpeed > minSpeed) {
      _gameSpeed -= speedStep;
      _restartTimerWithNewSpeed();
      notifyListeners();
    }
  }

  // Decrease snake speed
  void decreaseSpeed() {
    if (_gameSpeed < maxSpeed) {
      _gameSpeed += speedStep;
      _restartTimerWithNewSpeed();
      notifyListeners();
    }
  }

  // Restart timer with new speed
  void _restartTimerWithNewSpeed() {
    if (_isGameRunning) {
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(Duration(milliseconds: _gameSpeed), (timer) {
        _moveSnake();
      });
    }
  }

  // Pause the game
  void pauseGame() {
    if (_isGameRunning) {
      _isGameRunning = false;
      _gameTimer?.cancel();
      notifyListeners();
    }
  }

  // End the game
  void endGame() {
    _isGameRunning = false;
    _gameTimer?.cancel();
    notifyListeners();
  }

  // Change snake direction
  void changeDirection(Direction newDirection) {
    // Prevent 180-degree turns
    if ((_direction == Direction.up && newDirection == Direction.down) ||
        (_direction == Direction.down && newDirection == Direction.up) ||
        (_direction == Direction.left && newDirection == Direction.right) ||
        (_direction == Direction.right && newDirection == Direction.left)) {
      return;
    }

    _direction = newDirection;
  }

  // Move the snake
  void _moveSnake() {
    if (!_isGameRunning || _isGameOver) return;

    // Get the current head position
    Position head = _snake.first;

    // Calculate new head position based on direction
    Position newHead;
    switch (_direction) {
      case Direction.up:
        newHead = Position(head.row - 1, head.col);
        break;
      case Direction.down:
        newHead = Position(head.row + 1, head.col);
        break;
      case Direction.left:
        newHead = Position(head.row, head.col - 1);
        break;
      case Direction.right:
        newHead = Position(head.row, head.col + 1);
        break;
    }

    // Handle wraparound (if snake goes out of bounds)
    Position wrappedHead = Position(
        newHead.row < 0 ? rows - 1 : (newHead.row >= rows ? 0 : newHead.row),
        newHead.col < 0 ? cols - 1 : (newHead.col >= cols ? 0 : newHead.col));
    newHead = wrappedHead;

    // Check if snake collides with itself (game over condition)
    for (int i = 1; i < _snake.length; i++) {
      if (newHead.row == _snake[i].row && newHead.col == _snake[i].col) {
        _gameOver();
        return;
      }
    }

    // Check if snake ate food
    bool ateFood =
        _food != null && newHead.row == _food!.row && newHead.col == _food!.col;

    // Add new head to the snake
    _snake.insert(0, newHead);

    // If snake didn't eat food, remove the tail
    if (!ateFood) {
      _snake.removeLast();
    } else {
      // If snake ate food, increment score and generate new food
      _score++;
      _generateFood();
    }

    // Update the grid
    _updateGrid();

    notifyListeners();
  }

  // Handle game over
  void _gameOver() {
    _isGameRunning = false;
    _isGameOver = true;
    _gameTimer?.cancel();
    notifyListeners();
  }

  // Generate food at random position
  void _generateFood() {
    Random random = Random();
    int row, col;

    // Generate food at a position not occupied by the snake
    do {
      row = random.nextInt(rows);
      col = random.nextInt(cols);
    } while (_snake.contains(Position(row, col)));

    _food = Position(row, col);
  }

  // Update the grid based on snake and food positions
  void _updateGrid() {
    // Clear the grid
    _gameGrid = List.generate(rows, (i) => List.generate(cols, (j) => false));

    // Set snake positions to true
    for (var pos in _snake) {
      if (pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols) {
        _gameGrid[pos.row][pos.col] = true;
      }
    }

    // Set food position to true
    if (_food != null) {
      _gameGrid[_food!.row][_food!.col] = true;
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}