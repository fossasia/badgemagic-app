import 'package:badgemagic/bademagic_module/models/brightness.dart';
import 'package:badgemagic/providers/brightness_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrightnessProvider', () {
    test('should initialize with 100% brightness', () {
      final provider = BrightnessProvider();
      
      expect(provider.getBrightness(), Brightness.hundred);
      expect(provider.getBrightnessPercentage(), 100);
    });

    test('should update brightness and notify listeners', () {
      final provider = BrightnessProvider();
      bool listenerCalled = false;
      
      provider.addListener(() {
        listenerCalled = true;
      });
      
      provider.setBrightness(Brightness.fifty);
      
      expect(provider.getBrightness(), Brightness.fifty);
      expect(provider.getBrightnessPercentage(), 50);
      expect(listenerCalled, true);
    });

    test('should handle all brightness levels correctly', () {
      final provider = BrightnessProvider();
      
      // Test 25%
      provider.setBrightness(Brightness.twentyFive);
      expect(provider.getBrightnessPercentage(), 25);
      
      // Test 50%
      provider.setBrightness(Brightness.fifty);
      expect(provider.getBrightnessPercentage(), 50);
      
      // Test 75%
      provider.setBrightness(Brightness.seventyFive);
      expect(provider.getBrightnessPercentage(), 75);
      
      // Test 100%
      provider.setBrightness(Brightness.hundred);
      expect(provider.getBrightnessPercentage(), 100);
    });
  });
}
