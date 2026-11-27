import 'package:badgemagic/badge_animation/ani_left.dart';
import 'package:badgemagic/badge_animation/ani_right.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/view/widgets/animated_badge.dart';
import 'package:badgemagic/view/widgets/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

bool isFullyBlank(List<List<bool>> grid) =>
    grid.every((row) => row.every((cell) => !cell));

void main() {
  group('AnimationBadge preview', () {
    // 11x12 checkerboard content: every column has lit cells, so any
    // fully blank frame in the preview is the animation's fault.
    final content =
        List.generate(11, (i) => List.generate(12, (j) => (i + j) % 2 == 0));

    Future<void> pumpPreview(
        WidgetTester tester, AnimationBadgeProvider provider) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AnimationBadgeProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: AnimationBadge())),
          ),
        ),
      );
      await tester.pump();
    }

    List<List<bool>> previewGrid(WidgetTester tester) {
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AnimationBadge),
          matching: find.byType(CustomPaint),
        ),
      );
      return (customPaint.painter as BadgePaint).grid;
    }

    testWidgets('left scrolling preview never shows a blank frame',
        (tester) async {
      final provider = AnimationBadgeProvider();
      provider.setNewGrid(content);
      provider.setAnimationMode(LeftAnimation());
      await pumpPreview(tester, provider);

      for (var frame = 0; frame < content[0].length; frame++) {
        await tester.pump(const Duration(milliseconds: 500));
        final grid = provider.getPaintGrid();
        expect(isFullyBlank(grid), isFalse, reason: 'frame $frame blank');
        expect(previewGrid(tester), equals(grid));
      }
      provider.stopAnimation();
    });

    testWidgets('right scrolling preview never shows a blank frame',
        (tester) async {
      final provider = AnimationBadgeProvider();
      provider.setNewGrid(content);
      provider.setAnimationMode(RightAnimation());
      await pumpPreview(tester, provider);

      for (var frame = 0; frame < content[0].length; frame++) {
        await tester.pump(const Duration(milliseconds: 500));
        final grid = provider.getPaintGrid();
        expect(isFullyBlank(grid), isFalse, reason: 'frame $frame blank');
        expect(previewGrid(tester), equals(grid));
      }
      provider.stopAnimation();
    });
  });
}
