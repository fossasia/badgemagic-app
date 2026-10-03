import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DrawBadgeProvider provider;

  setUp(() {
    provider = DrawBadgeProvider();
  });

  List<List<bool>> emptyGrid() => List.generate(
        provider.rows,
        (_) => List.filled(provider.cols, false),
      );

  List<List<bool>> filledGrid() => List.generate(
        provider.rows,
        (_) => List.filled(provider.cols, true),
      );

  void setGrid(List<List<bool>> grid) {
    provider.updateDrawViewGrid(grid);
  }

  group('DrawBadgeProvider.shiftDrawing', () {
    test('shifts left with wrap-around', () {
      final grid = emptyGrid();
      grid[0][0] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.left);

      final result = provider.getDrawViewGrid();
      expect(result[0][provider.cols - 1], isTrue);
      expect(result[0][0], isFalse);
    });

    test('shifts right with wrap-around', () {
      final grid = emptyGrid();
      grid[0][provider.cols - 1] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.right);

      final result = provider.getDrawViewGrid();
      expect(result[0][0], isTrue);
      expect(result[0][provider.cols - 1], isFalse);
    });

    test('shifts up with wrap-around', () {
      final grid = emptyGrid();
      grid[0][5] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.up);

      final result = provider.getDrawViewGrid();
      expect(result[provider.rows - 1][5], isTrue);
      expect(result[0][5], isFalse);
    });

    test('shifts down with wrap-around', () {
      final grid = emptyGrid();
      grid[provider.rows - 1][5] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.down);

      final result = provider.getDrawViewGrid();
      expect(result[0][5], isTrue);
      expect(result[provider.rows - 1][5], isFalse);
    });

    test('keeps an empty grid empty after any shift', () {
      setGrid(emptyGrid());

      provider.shiftDrawing(DrawMoveDirection.left);
      provider.shiftDrawing(DrawMoveDirection.right);
      provider.shiftDrawing(DrawMoveDirection.up);
      provider.shiftDrawing(DrawMoveDirection.down);

      expect(provider.getDrawViewGrid(), emptyGrid());
    });

    test('keeps a filled grid filled after any shift', () {
      setGrid(filledGrid());

      provider.shiftDrawing(DrawMoveDirection.left);
      provider.shiftDrawing(DrawMoveDirection.up);

      expect(provider.getDrawViewGrid(), filledGrid());
    });

    test('preserves an L-shaped pattern when shifting right', () {
      final grid = emptyGrid();
      // Vertical bar at col 0, rows 0-2; horizontal bar at row 2, cols 0-2
      grid[0][0] = true;
      grid[1][0] = true;
      grid[2][0] = true;
      grid[2][1] = true;
      grid[2][2] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.right);

      final result = provider.getDrawViewGrid();
      expect(result[0][1], isTrue);
      expect(result[1][1], isTrue);
      expect(result[2][1], isTrue);
      expect(result[2][2], isTrue);
      expect(result[2][3], isTrue);
      expect(result[0][0], isFalse);
      expect(result[2][0], isFalse);
    });

    test('wraps a pattern touching all four edges', () {
      final grid = emptyGrid();
      grid[0][0] = true;
      grid[0][provider.cols - 1] = true;
      grid[provider.rows - 1][0] = true;
      grid[provider.rows - 1][provider.cols - 1] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.left);

      final result = provider.getDrawViewGrid();
      expect(result[0][provider.cols - 1], isTrue);
      expect(result[0][provider.cols - 2], isTrue);
      expect(result[provider.rows - 1][provider.cols - 1], isTrue);
      expect(result[provider.rows - 1][provider.cols - 2], isTrue);
      expect(result[0][0], isFalse);
      expect(result[provider.rows - 1][0], isFalse);
    });

    test('opposite moves restore the original pattern', () {
      final grid = emptyGrid();
      grid[3][7] = true;
      grid[4][8] = true;
      setGrid(grid);
      final original = provider.getDrawViewGrid();

      provider.shiftDrawing(DrawMoveDirection.left);
      provider.shiftDrawing(DrawMoveDirection.right);
      expect(provider.getDrawViewGrid(), original);

      provider.shiftDrawing(DrawMoveDirection.up);
      provider.shiftDrawing(DrawMoveDirection.down);
      expect(provider.getDrawViewGrid(), original);
    });

    test('undo after a move restores the previous grid', () {
      final grid = emptyGrid();
      grid[2][3] = true;
      setGrid(grid);
      final beforeMove = provider.getDrawViewGrid();

      provider.shiftDrawing(DrawMoveDirection.right);
      expect(provider.getDrawViewGrid()[2][4], isTrue);
      expect(provider.canUndo, isTrue);

      provider.undo();
      expect(provider.getDrawViewGrid(), beforeMove);
    });

    test('redo after undo restores the moved grid', () {
      final grid = emptyGrid();
      grid[2][3] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.right);
      final afterMove = provider.getDrawViewGrid();

      provider.undo();
      expect(provider.canRedo, isTrue);

      provider.redo();
      expect(provider.getDrawViewGrid(), afterMove);
    });

    test('multiple consecutive moves each create undo steps', () {
      final grid = emptyGrid();
      grid[1][1] = true;
      setGrid(grid);

      provider.shiftDrawing(DrawMoveDirection.right);
      provider.shiftDrawing(DrawMoveDirection.right);
      expect(provider.getDrawViewGrid()[1][3], isTrue);

      provider.undo();
      expect(provider.getDrawViewGrid()[1][2], isTrue);

      provider.undo();
      expect(provider.getDrawViewGrid()[1][1], isTrue);
    });
  });
}
