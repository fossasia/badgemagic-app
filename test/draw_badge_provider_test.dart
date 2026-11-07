import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shape commit does not add a second undo snapshot', () {
    final provider = DrawBadgeProvider();

    provider.pushToUndoStack();
    provider.setCell(0, 0, true);

    provider.pushToUndoStack();
    provider.setCell(1, 1, true, preview: true);
    provider.commitGridUpdate();

    expect(provider.getDrawViewGrid()[0][0], isTrue);
    expect(provider.getDrawViewGrid()[1][1], isTrue);

    provider.undo();
    expect(provider.getDrawViewGrid()[0][0], isTrue);
    expect(provider.getDrawViewGrid()[1][1], isFalse);

    provider.undo();
    expect(provider.getDrawViewGrid()[0][0], isFalse);
    expect(provider.getDrawViewGrid()[1][1], isFalse);
  });

  test('reset still records its own undo snapshot', () {
    final provider = DrawBadgeProvider();
    provider.setCell(0, 0, true);
    provider.resetDrawViewGrid();

    expect(provider.getDrawViewGrid()[0][0], isFalse);

    provider.undo();
    expect(provider.getDrawViewGrid()[0][0], isTrue);
  });
}
