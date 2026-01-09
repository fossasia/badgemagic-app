import 'package:badgemagic/bademagic_module/models/brightness.dart';
import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data.fromJson brightness handling', () {
    test('should handle valid brightness hex value', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': '0x20'
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.fifty);
    });

    test('should default to hundred when brightness key is missing', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ]
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.hundred);
    });

    test('should default to hundred when brightness value is null', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': null
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.hundred);
    });

    test('should default to hundred when brightness is not a string', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': 123
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.hundred);
    });

    test('should default to hundred when brightness is an empty string', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': ''
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.hundred);
    });

    test('should default to hundred when brightness is an object', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': {'value': '0x20'}
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.hundred);
    });

    test('should default to hundred when brightness is an array', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': ['0x20']
      };

      final data = Data.fromJson(json);
      
      expect(data.brightness, Brightness.hundred);
    });

    test('should handle all valid brightness values', () {
      final testCases = [
        {'hex': '0x30', 'expected': Brightness.twentyFive},
        {'hex': '0x20', 'expected': Brightness.fifty},
        {'hex': '0x10', 'expected': Brightness.seventyFive},
        {'hex': '0x00', 'expected': Brightness.hundred},
      ];

      for (var testCase in testCases) {
        final json = {
          'messages': [
            {
              'text': ['A']
            }
          ],
          'brightness': testCase['hex']
        };

        final data = Data.fromJson(json);
        
        expect(data.brightness, testCase['expected'],
            reason: 'Brightness ${testCase['hex']} should map to ${testCase['expected']}');
      }
    });

    test('should default to hundred for unrecognized brightness hex values', () {
      final json = {
        'messages': [
          {
            'text': ['A']
          }
        ],
        'brightness': '0xFF'
      };

      final data = Data.fromJson(json);
      
      // fromHex returns hundred as default when value is not recognized
      expect(data.brightness, Brightness.hundred);
    });
  });
}
