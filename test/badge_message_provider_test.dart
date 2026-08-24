import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_ble/universal_ble.dart';

class _PoweredOnBlePlatform extends UniversalBlePlatform {
  @override
  Future<AvailabilityState> getBluetoothAvailabilityState() async {
    return AvailabilityState.poweredOn;
  }
}

class _CapturingBadgeMessageProvider extends BadgeMessageProvider {
  Data? transferredData;

  @override
  Future<void> transferData(
    DataTransferManager manager, {
    BuildContext? context,
  }) async {
    transferredData = manager.data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<InlineImageProvider>()) {
      getIt.registerSingleton<InlineImageProvider>(InlineImageProvider());
    }

    if (!getIt.isRegistered<LocalizationService>()) {
      final localizationService = LocalizationService();
      await localizationService.init(const Locale('en'));
      getIt.registerSingleton<LocalizationService>(localizationService);
    }

    if (!getIt.isRegistered<BleDialogController>()) {
      getIt.registerSingleton<BleDialogController>(BleDialogController());
    }

    UniversalBle.setInstance(_PoweredOnBlePlatform());
  });

  testWidgets('batch transfer keeps the first saved badge settings',
      (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(),
    ));
    final provider = _CapturingBadgeMessageProvider();
    final context = tester.element(find.byType(SizedBox));
    final savedBadges = Data(messages: [
      Message(text: ['first'], speed: Speed.eight, mode: Mode.left),
      Message(text: ['second'], speed: Speed.eight, mode: Mode.left),
    ]);

    await provider.checkAndTransfer(
      null,
      null,
      null,
      null,
      null,
      null,
      savedBadges.toJson(),
      true,
      context,
    );

    expect(provider.transferredData, isNotNull);
    expect(provider.transferredData!.messages[0].speed, Speed.eight);
    expect(provider.transferredData!.messages[0].mode, Mode.left);
    expect(provider.transferredData!.messages[1].speed, Speed.eight);
    expect(provider.transferredData!.messages[1].mode, Mode.left);
  });
}
