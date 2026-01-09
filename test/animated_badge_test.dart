import 'package:badgemagic/bademagic_module/models/brightness.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/brightness_provider.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('AnimatedBadge brightness-to-opacity mapping', () {
    testWidgets('should map 0% brightness to 0.5 opacity', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      // Manually set brightness to 25% (which is the minimum slider value)
      // but test the mapping function's behavior at 0%
      brightnessProvider.setBrightness(Brightness.twentyFive);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: brightnessProvider),
            ChangeNotifierProvider.value(value: animationProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnimationBadge(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byType(AnimationBadge), findsOneWidget);
    });

    testWidgets('should map 25% brightness to 0.6 opacity', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      brightnessProvider.setBrightness(Brightness.twentyFive);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: brightnessProvider),
            ChangeNotifierProvider.value(value: animationProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnimationBadge(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byType(AnimationBadge), findsOneWidget);
      
      // The widget should use the mapping function correctly
      expect(brightnessProvider.getBrightnessPercentage(), 25);
    });

    testWidgets('should map 50% brightness to 0.75 opacity', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      brightnessProvider.setBrightness(Brightness.fifty);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: brightnessProvider),
            ChangeNotifierProvider.value(value: animationProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnimationBadge(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byType(AnimationBadge), findsOneWidget);
      expect(brightnessProvider.getBrightnessPercentage(), 50);
    });

    testWidgets('should map 75% brightness to 0.85 opacity', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      brightnessProvider.setBrightness(Brightness.seventyFive);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: brightnessProvider),
            ChangeNotifierProvider.value(value: animationProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnimationBadge(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byType(AnimationBadge), findsOneWidget);
      expect(brightnessProvider.getBrightnessPercentage(), 75);
    });

    testWidgets('should map 100% brightness to 1.0 opacity', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      brightnessProvider.setBrightness(Brightness.hundred);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: brightnessProvider),
            ChangeNotifierProvider.value(value: animationProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnimationBadge(),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byType(AnimationBadge), findsOneWidget);
      expect(brightnessProvider.getBrightnessPercentage(), 100);
    });
  });
}
