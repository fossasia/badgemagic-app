import 'dart:io';

import 'package:badgemagic/communication/base_ble_state.dart';
import 'package:badgemagic/communication/datagenerator.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/communication/scan_state.dart';
import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/models/messages.dart';
import 'package:badgemagic/models/mode.dart';
import 'package:badgemagic/models/speed.dart';
import 'package:badgemagic/providers/badge_scan_provider.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:badgemagic/others/custom_transfers/transfers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/others/app_logger.dart';
import 'package:provider/provider.dart';

import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';

Map<int, Mode> modeValueMap = {
  0: Mode.left,
  1: Mode.right,
  2: Mode.up,
  3: Mode.down,
  4: Mode.fixed,
  5: Mode.animation,
  6: Mode.snowflake,
  7: Mode.picture,
  8: Mode.laser,
  9: Mode.pacman,
  10: Mode.chevronleft,
  11: Mode.diamond,
  12: Mode.brokenhearts,
  13: Mode.cupid,
  14: Mode.feet,
};

Map<int, Speed> speedMap = {
  1: Speed.one,
  2: Speed.two,
  3: Speed.three,
  4: Speed.four,
  5: Speed.five,
  6: Speed.six,
  7: Speed.seven,
  8: Speed.eight,
};

class BadgeMessageProvider {
  InlineImageProvider controllerData =
      GetIt.instance.get<InlineImageProvider>();
  FileHelper fileHelper = FileHelper();
  Converters converters = Converters();

  Future<Data> getBadgeData(String text, bool flash, bool marq, Speed speed,
      Mode mode, bool isInverted) async {
    List<String> message = await converters.messageTohex(text, isInverted);
    Data data = Data(messages: [
      Message(
        text: message,
        flash: flash,
        marquee: marq,
        speed: speed,
        mode: mode,
      )
    ]);
    return data;
  }

  Future<Data> generateData(
      String? text,
      bool? flash,
      bool? marq,
      bool? inverted,
      Speed? speed,
      Mode? mode,
      Map<String, dynamic>? jsonData) async {
    if (jsonData != null) {
      return fileHelper.jsonToData(jsonData);
    } else {
      return getBadgeData(text ?? '', flash ?? false, marq ?? false,
          speed ?? Speed.one, mode ?? Mode.left, inverted ?? false);
    }
  }

  Future<void> transferData(
    DataTransferManager manager, {
    BuildContext? context,
  }) async {
    final scanProvider = context != null
        ? Provider.of<BadgeScanProvider>(context, listen: false)
        : null;

    final BleState initialState = ScanState(
      manager: manager,
      mode: scanProvider?.mode ?? BadgeScanMode.any,
      allowedNames: scanProvider?.getSelectedBadgeNames() ?? <String>[],
    );

    BleState? state = initialState;

    while (state != null) {
      state = await state.process();
    }
  }

  Future<void> checkAndTransfer(
      String? text,
      bool? flash,
      bool? marq,
      bool? isInverted,
      int? speed,
      Mode? mode,
      Map<String, dynamic>? jsonData,
      bool isSavedBadge,
      BuildContext context,
      {TextStyle? textStyle}) async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final bleDialogController = GetIt.instance<BleDialogController>();

    if (controllerData.getController().text.isEmpty && isSavedBadge == false) {
      bool isFireworks = false;
      try {
        int fireworksIndex = 19;
        int cycleIndex = 20;
        if (mode == Mode.fixed &&
            modeValueMap.containsKey(fireworksIndex) &&
            modeValueMap[fireworksIndex] == Mode.fixed) {
          isFireworks = true;
        }
        if (mode == Mode.cycle &&
            modeValueMap.containsKey(cycleIndex) &&
            modeValueMap[cycleIndex] == Mode.cycle) {}
      } catch (_) {}
      if (mode != Mode.pacman && !isFireworks) {
        bleDialogController.update(
            BleDialogStatus.error, l10n.pleaseEnterMessage);
        return;
      }
    }

    if (Platform.isAndroid) {
      PermissionStatus connectStatus = await Permission.bluetoothConnect.status;

      if (!connectStatus.isGranted) {
        connectStatus = await Permission.bluetoothConnect.request();

        if (!connectStatus.isGranted) {
          bleDialogController.update(BleDialogStatus.error, l10n.turnBLEOn);
          return;
        }
      }
    }

    AvailabilityState adapterState =
        await UniversalBle.getBluetoothAvailabilityState();

    if (adapterState != AvailabilityState.poweredOn) {
      try {
        await UniversalBle.enableBluetooth();
      } catch (e) {
        bleDialogController.update(
            BleDialogStatus.error, l10n.turnOnBluetoothMessage);
      }
      logger.w('Bluetooth is currently disabled/unavailable: $adapterState');
      return;
    }

    Data data;
    if (jsonData != null) {
      data = fileHelper.jsonToData(jsonData);
      if (isSavedBadge && data.messages.isNotEmpty) {
        final old = data.messages[0];
        final combinedBadges =
            data.messages.where((m) => m.text.isNotEmpty).length > 1;
        final newMessage = Message(
          text: old.text,
          flash: old.flash,
          marquee: old.marquee,
          speed: old.speed,
          mode: combinedBadges ? Mode.animation : old.mode,
        );
        data = Data(messages: [newMessage, ...data.messages.skip(1)]);
      }
    } else {
      data = await generateData(
          text, flash, marq, isInverted, speedMap[speed], mode, jsonData);
    }

    DataTransferManager manager = DataTransferManager(data);
    await transferData(manager, context: context);
  }
}

Future<void> transferFireworksAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferFireworksAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferBeatingHeartsAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferBeatingHeartsAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferEmergencyAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferEmergencyAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferDiagonalAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferDiagonalAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferFishAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferFishAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferEqualizerAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferEqualizerAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferPacmanAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferPacmanAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferChevronAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferChevronAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferDiamondAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferDiamondAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferBrokenHeartsAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferBrokenHeartsAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferFeetAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferFeetAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferCupidAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferCupidAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}

Future<void> transferCycleAnimation(
    BadgeMessageProvider badgeDataProvider, int speedLevel) async {
  return customTransferCycleAnimation(
      (manager) => badgeDataProvider.transferData(manager), speedLevel);
}
