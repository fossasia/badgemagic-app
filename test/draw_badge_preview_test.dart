import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/badge_paint.dart';
import 'package:badgemagic/view/widgets/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshPreviewGrid notifies listeners after preview cells are set', () {
    final provider = DrawBadgeProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
        provider.setCell(5 + i, 10 + j, true, preview: true);
      }
    }
    expect(notifications, 0);

    provider.refreshPreviewGrid();
    expect(notifications, 1);
    expect(
      provider.getDrawViewGrid().expand((row) => row).any((cell) => cell),
      isTrue,
    );
  });

  for (final shape in [
    DrawShape.square,
    DrawShape.rectangle,
    DrawShape.circle,
    DrawShape.triangle,
  ]) {
    testWidgets('$shape is painted while dragging before commit', (
      tester,
    ) async {
      late DrawBadgeProvider provider;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 440,
              child: BMBadge(
                providerInit: (value) {
                  provider = value;
                  provider.setShape(shape);
                },
              ),
            ),
          ),
        ),
      );

      final badge = find.byType(BMBadge);
      final gesture = await tester.startGesture(tester.getCenter(badge));
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();

      var previewNotifications = 0;
      provider.addListener(() => previewNotifications++);
      await gesture.moveBy(const Offset(24, 24));
      await tester.pump();

      final paint = tester.widget<CustomPaint>(
        find.descendant(of: badge, matching: find.byType(CustomPaint)),
      );
      final preview = (paint.painter! as BadgePaint).grid;
      expect(preview.expand((row) => row).any((value) => value), isTrue);
      expect(preview, provider.getDrawViewGrid());
      expect(previewNotifications, 1);

      await gesture.up();
      await tester.pump();
      expect(provider.getDrawViewGrid(), preview);
    });
  }
}
