import 'dart:convert';
import 'dart:io';

import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

typedef TestCallback = Future<void> Function(Directory tempDir);

Future<void> withTempDir(TestCallback callback) async {
  final tempDir = await Directory.systemTemp.createTemp('badgemagic_test_');
  final oldProvider = PathProviderPlatform.instance;
  PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  try {
    await callback(tempDir);
  } finally {
    PathProviderPlatform.instance = oldProvider;
    await tempDir.delete(recursive: true);
  }
}

class _FakePathProvider extends PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

Map<String, dynamic> _createBadgeData(String messageText) {
  return {
    'messages': [
      {
        'text': [messageText],
        'flash': false,
        'marquee': false,
        'speed': '0x70',
        'mode': '0x00',
        'invert': false,
      }
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (!GetIt.I.isRegistered<InlineImageProvider>()) {
      GetIt.I.registerSingleton<InlineImageProvider>(InlineImageProvider());
    }
  });

  group('FileHelper uniqueBadgeFilename', () {
    test('returns original filename when no conflicting file exists', () async {
      await withTempDir((dir) async {
        final fileHelper = FileHelper();
        final filename = await fileHelper.uniqueBadgeFilename('Demo.json');
        expect(filename, 'Demo');
      });
    });

    test('appends (1) suffix when file already exists', () async {
      await withTempDir((dir) async {
        final fileHelper = FileHelper();
        await File('${dir.path}/Demo.json').writeAsString('{}');

        final filename = await fileHelper.uniqueBadgeFilename('Demo.json');
        expect(filename, 'Demo (1)');
      });
    });

    test('generates incrementing suffixes on repeated duplicates', () async {
      await withTempDir((dir) async {
        final fileHelper = FileHelper();
        await File('${dir.path}/Demo.json').writeAsString('{}');
        await File('${dir.path}/Demo (1).json').writeAsString('{}');

        final filename = await fileHelper.uniqueBadgeFilename('Demo.json');
        expect(filename, 'Demo (2)');
      });
    });

    test(
        'does not overwrite existing file when incoming name already has a suffix',
        () async {
      await withTempDir((dir) async {
        final fileHelper = FileHelper();
        await File('${dir.path}/Demo.json').writeAsString('{}');
        await File('${dir.path}/Demo (1).json').writeAsString('{}');

        final filename = await fileHelper.uniqueBadgeFilename('Demo (1).json');
        expect(filename, 'Demo (1) (1)');
      });
    });

    test('finds first available incremented filename if gap exists', () async {
      await withTempDir((dir) async {
        final fileHelper = FileHelper();
        await File('${dir.path}/Demo.json').writeAsString('{}');
        await File('${dir.path}/Demo (2).json').writeAsString('{}');

        final filename = await fileHelper.uniqueBadgeFilename('Demo.json');
        expect(filename, 'Demo (1)');
      });
    });
  });

  group('FileHelper badge import flow', () {
    test(
        'preserves existing badge file and saves duplicate with unique name, retaining data',
        () async {
      await withTempDir((dir) async {
        final fileHelper = FileHelper();
        final originalData = _createBadgeData('Original Badge');
        final importedData1 = _createBadgeData('Imported Badge 1');
        final importedData2 = _createBadgeData('Imported Badge 2');

        final originalFile = File('${dir.path}/Demo.json');
        await originalFile.writeAsString(jsonEncode(originalData));

        final importSuccess1 = await fileHelper.importBadgeFromJson({
          'name': 'Demo',
          'badge': importedData1,
        });
        expect(importSuccess1, isTrue);

        final originalContent = jsonDecode(await originalFile.readAsString())
            as Map<String, dynamic>;
        expect(
          originalContent['messages'][0]['text'],
          ['Original Badge'],
        );

        final duplicateFile1 = File('${dir.path}/Demo (1).json');
        expect(await duplicateFile1.exists(), isTrue);
        final duplicateContent1 =
            jsonDecode(await duplicateFile1.readAsString())
                as Map<String, dynamic>;
        expect(
          duplicateContent1['messages'][0]['text'],
          ['Imported Badge 1'],
        );

        final importSuccess2 = await fileHelper.importBadgeFromJson({
          'name': 'Demo',
          'badge': importedData2,
        });
        expect(importSuccess2, isTrue);

        final duplicateFile2 = File('${dir.path}/Demo (2).json');
        expect(await duplicateFile2.exists(), isTrue);
        final duplicateContent2 =
            jsonDecode(await duplicateFile2.readAsString())
                as Map<String, dynamic>;
        expect(
          duplicateContent2['messages'][0]['text'],
          ['Imported Badge 2'],
        );

        // Verify getBadgeDataFiles reflects all saved and imported badges
        await fileHelper.getBadgeDataFiles();
        final cachedKeys = GetIt.I<InlineImageProvider>()
            .savedBadgeCache
            .map((entry) => entry.key)
            .toList();

        expect(cachedKeys, contains('Demo.json'));
        expect(cachedKeys, contains('Demo (1).json'));
        expect(cachedKeys, contains('Demo (2).json'));
      });
    });
  });
}
