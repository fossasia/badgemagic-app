import 'package:badgemagic/bademagic_module/models/brightness.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/brightness_provider.dart';
import 'package:badgemagic/providers/getitlocator.dart';
import 'package:badgemagic/view/widgets/brightness_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() {
    setupLocator();
  });

  group('BrightnessControl widget', () {
    testWidgets('should update brightness without setState', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: brightnessProvider),
              ChangeNotifierProvider.value(value: animationProvider),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BrightnessControl(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Initial brightness should be 100%
      expect(brightnessProvider.getBrightnessPercentage(), 100);
      
      // Find the slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      
      // Change the slider value to 50
      await tester.drag(slider, const Offset(-100.0, 0.0));
      await tester.pumpAndSettle();
      
      // Provider should be updated through notifyListeners, not setState
      // The exact value might vary due to slider behavior, but it should have changed
      expect(brightnessProvider.getBrightnessPercentage(), isNot(100));
    });

    testWidgets('should disable slider when animation is active', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      // Set a special animation that should disable brightness control
      animationProvider.setSelectedAnimation('laser');
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: brightnessProvider),
              ChangeNotifierProvider.value(value: animationProvider),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BrightnessControl(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Find the slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      
      // Get the Slider widget
      final sliderWidget = tester.widget<Slider>(slider);
      
      // The slider should be disabled (onChanged is null) when animation is active
      expect(sliderWidget.onChanged, isNull);
    });

    testWidgets('should notify listeners when brightness changes', (WidgetTester tester) async {
      final brightnessProvider = BrightnessProvider();
      final animationProvider = AnimationBadgeProvider();
      
      bool listenerCalled = false;
      brightnessProvider.addListener(() {
        listenerCalled = true;
      });
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: brightnessProvider),
              ChangeNotifierProvider.value(value: animationProvider),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BrightnessControl(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Reset the flag after initial build
      listenerCalled = false;
      
      // Change brightness programmatically
      brightnessProvider.setBrightness(Brightness.fifty);
      await tester.pumpAndSettle();
      
      // Listener should have been called
      expect(listenerCalled, true);
      expect(brightnessProvider.getBrightnessPercentage(), 50);
    });
  });
}
