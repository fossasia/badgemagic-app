import 'dart:io';

import 'package:badgemagic/models/data.dart';
import 'package:badgemagic/others/data_to_bytearray_converter.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:get_it/get_it.dart';

import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';

Future<bool> checkAdapterState() async {
  final adapterState = await UniversalBle.getBluetoothAvailabilityState();
  final l10n = GetIt.instance.get<LocalizationService>().l10n;
  final bleDialogController = GetIt.instance<BleDialogController>();

  if (Platform.isAndroid) {
    PermissionStatus connectStatus = await Permission.bluetoothConnect.status;

    if (!connectStatus.isGranted) {
      connectStatus = await Permission.bluetoothConnect.request();

      if (!connectStatus.isGranted) {
        bleDialogController.update(BleDialogStatus.error, l10n.turnBLEOn);
        return false;
      }
    }
  }

  if (adapterState != AvailabilityState.poweredOn) {
    try {
      await UniversalBle.enableBluetooth();
    } catch (e) {
      bleDialogController.update(BleDialogStatus.error, l10n.turnBLEOn);
    }
    return false;
  }
  return true;
}

class DataTransferManager {
  final Data data;

  BleDevice? connectedDevice;

  final BadgeMessageProvider badgeData = BadgeMessageProvider();
  final DataToByteArrayConverter converter = DataToByteArrayConverter();
  final FileHelper fileHelper = FileHelper();
  final InlineImageProvider controllerData =
      GetIt.instance<InlineImageProvider>();

  DataTransferManager(this.data);

  Future<List<List<int>>> generateDataChunk() async {
    return converter.convert(data);
  }

  /// Helper to clear the currently connected device.
  void clearConnectedDevice() {
    connectedDevice = null;
  }
}

class RawDataTransferManager extends DataTransferManager {
  final String pin;
  final Data textData;

  RawDataTransferManager({required this.pin, required this.textData})
      : super(textData);

  @override
  Future<List<List<int>>> generateDataChunk() async {
    List<List<int>> textChunks = await converter.convert(textData);

    List<String> pinHex = pin.codeUnits
        .map((char) => char.toRadixString(16).padLeft(2, '0'))
        .toList();

    while (pinHex.length < 16) {
      pinHex.add("00");
    }
    List<int> parsedPinBytes =
        pinHex.map((h) => int.parse(h, radix: 16)).toList();
    return [parsedPinBytes, ...textChunks];
  }
}
