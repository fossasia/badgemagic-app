import 'dart:io';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:badgemagic/main.dart' as app;
import 'package:badgemagic/constants.dart';
import 'utils.dart';

void main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    return Future(() async {
      WidgetsApp.debugAllowBannerOverride = false; // Hide the debug banner
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }
    });
  });

  group('E2E Group', () {
    testWidgets('Take Screenshots', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final homeScreenTitle = find.byKey(const ValueKey(homeScreenTitleKey));
      final savedBadgeScreenTitle =
          find.byKey(const ValueKey(savedBadgeScreen));
      final drawBadgeScreenTitle = find.byKey(const ValueKey(drawBadgeScreen));

      await pumpUntilFound(tester, homeScreenTitle);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('1_home_screen');

      final transitionTabText = find.text('Transition');
      await tester.tap(transitionTabText);
      await tester.pumpAndSettle();

      final fixedAnimationContainer = find.text('Fixed');
      await tester.tap(fixedAnimationContainer);
      await tester.pumpAndSettle();

      final speedTabText = find.text('Speed');
      await tester.tap(speedTabText);
      await tester.pumpAndSettle();

      final inputField = find.byType(ExtendedTextField);
      await tester.tap(inputField);
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('Hello');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await binding.takeScreenshot('2_text_badge');

      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final saveBadgeButton = find.byWidgetPredicate(
        (widget) =>
            widget is TextButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Save',
      );
      await tester.tap(saveBadgeButton);
      await tester.pumpAndSettle();

      await tester.tap(inputField);
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final prefixIcon = find.byIcon(Icons.tag_faces_outlined);
      await tester.tap(prefixIcon);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final gridViewCard = find.byWidgetPredicate(
        (widget) =>
            widget is Card &&
            widget.child is Padding &&
            (widget.child as Padding).child is Image,
      );

      final targetCard = gridViewCard.at(18);
      await tester.tap(targetCard);
      await tester.pumpAndSettle();
      await tester.tap(prefixIcon);
      await tester.pumpAndSettle();

      final effectsTabText = find.text('Effects');
      await tester.tap(effectsTabText);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('3_emoji_badge');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveBadgeButton);
      await tester.pumpAndSettle();

      final invertEffectContainer = find.text('Invert');
      await tester.tap(invertEffectContainer);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('4_inverted_emoji_badge');

      await tester.tap(invertEffectContainer);
      await tester.pumpAndSettle();
      await tester.tap(speedTabText);
      await tester.pumpAndSettle();

      ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();
      final savedBadgesText = find.text('Saved Badges');
      await tester.tap(savedBadgesText);
      await pumpUntilFound(tester, savedBadgeScreenTitle);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('5_saved_badges');

      final playButton = find
          .byWidgetPredicate(
            (widget) =>
                widget is IconButton &&
                widget.icon is Image &&
                (widget.icon as Image).image is AssetImage &&
                ((widget.icon as Image).image as AssetImage).assetName ==
                    "assets/icons/t_play.png",
          )
          .at(1);
      await tester.tap(playButton);
      await tester.pumpAndSettle();
      final badgeSwitch = find.byType(Switch).at(1);
      await tester.tap(badgeSwitch);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('6_saved_badges_clicked');

      state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();
      final drawBadgeText = find.text('Draw Clipart');
      await tester.tap(drawBadgeText);
      await pumpUntilFound(tester, drawBadgeScreenTitle);

      final badgeFinder = find.byWidgetPredicate(
        (widget) => widget is BMBadge,
      );
      await tester.drag(badgeFinder, const Offset(50, 0));
      await tester.pumpAndSettle();
      await tester.drag(badgeFinder, const Offset(-50, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('7_draw_badge');
    });
  });
}
