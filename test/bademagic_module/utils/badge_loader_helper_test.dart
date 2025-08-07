import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:badgemagic/bademagic_module/utils/badge_loader_helper.dart';
import 'package:badgemagic/bademagic_module/utils/badge_text_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/providers/imageprovider.dart';

// Mocks for path_provider to use a temp directory for tests
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register a dummy InlineImageProvider so FileHelper/GetIt works in tests.
  setUpAll(() {
    if (!GetIt.I.isRegistered<InlineImageProvider>()) {
      GetIt.I.registerSingleton<InlineImageProvider>(InlineImageProvider());
    }
  });

  group('BadgeLoaderHelper', () {
    test('loads badge data and original text correctly', () async {
      await withTempDir((dir) async {
        // Arrange
        final badgeFilename = 'badge1.json';
        final badgeData =
            '{"messages":[{"text":["Test123"],"flash":true,"marquee":false,"mode":"0","speed":"1"}],"invert":true}';
        final badgeFile = File('${dir.path}/$badgeFilename');
        await badgeFile.writeAsString(badgeData);
        await BadgeTextStorage.saveOriginalText(badgeFilename, 'Test123');

        // Act
        final (text, data, map) =
            await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename);

        // Assert
        expect(text, 'Test123');
        expect(data.messages[0].text, isA<List<String>>());
        expect(data.messages[0].text[0], 'Test123');
        expect(map!['invert'], true);
      });
    });

    test('falls back to Hello if original text missing', () async {
      await withTempDir((dir) async {
        final badgeFilename = 'badge2.json';
        final badgeData =
            '{"messages":[{"text":["FallbackTest"],"flash":false,"marquee":true,"mode":"1","speed":"2"}],"invert":false}';
        final badgeFile = File('${dir.path}/$badgeFilename');
        await badgeFile.writeAsString(badgeData);
        // Do NOT save original text

        final (text, data, map) =
            await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename);
        expect(text, 'Hello');
        expect(data.messages[0].text, isA<List<String>>());
        expect(data.messages[0].text[0], 'FallbackTest');
        expect(map!['invert'], false);
      });
    });

    test('throws if badge file missing', () async {
      await withTempDir((dir) async {
        final badgeFilename = 'doesnotexist.json';
        expect(
          () async =>
              await BadgeLoaderHelper.loadBadgeDataAndText(badgeFilename),
          throwsException,
        );
      });
    });

    test('parses animation mode from int and string', () {
      expect(BadgeLoaderHelper.parseAnimationMode(1), 1);
      expect(BadgeLoaderHelper.parseAnimationMode('1'), 1);
      expect(BadgeLoaderHelper.parseAnimationMode('BadgeMode.left'), 0);
      expect(BadgeLoaderHelper.parseAnimationMode('BadgeMode.right'), 1);
      expect(BadgeLoaderHelper.parseAnimationMode('BadgeMode.fixed'), 4);
      expect(BadgeLoaderHelper.parseAnimationMode('unknown'), 0);
    });
  });
}
