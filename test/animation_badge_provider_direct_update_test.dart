import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late AnimationBadgeProvider provider;

  setUpAll(() async {
    await GetIt.instance.reset();
    setupLocator();
  });

  setUp(() {
    provider = AnimationBadgeProvider();
  });

  tearDown(() {
    provider.stopAnimation();
  });

  group('sendDirectLegacyUpdate mode mapping', () {
    test('maps the selected animation index to a Mode value', () {
      provider.setAnimationMode(animationMap[4]);

      final Mode? mode = modeValueMap[provider.getAnimationIndex() ?? 0];

      expect(mode, Mode.fixed);
      expect(mode, isA<Mode>());
    });

    test('maps left animation to Mode.left', () {
      provider.setAnimationMode(animationMap[0]);

      final Mode? mode = modeValueMap[provider.getAnimationIndex() ?? 0];

      expect(mode, Mode.left);
    });

    test('generateData accepts Mode and stores it on the message', () async {
      final badgeData = BadgeMessageProvider();
      final data = await badgeData.generateData(
        'Hi',
        false,
        false,
        false,
        Speed.one,
        Mode.fixed,
        null,
      );

      expect(data.messages.single.mode, Mode.fixed);
    });
  });
}
