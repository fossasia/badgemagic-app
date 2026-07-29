import 'dart:io';

import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:get_it/get_it.dart';

import '../../services/localization_service.dart';
import '../utils/toast_utils.dart';

Future<bool> checkAdapterState() async {
  final adapterState = await UniversalBle.getBluetoothAvailabilityState();
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  if (Platform.isAndroid) {
    PermissionStatus connectStatus = await Permission.bluetoothConnect.status;

    if (!connectStatus.isGranted) {
      connectStatus = await Permission.bluetoothConnect.request();

      if (!connectStatus.isGranted) {
        ToastUtils().showErrorToast(l10n.turnBLEOn);
        return false;
      }
    }
  }

  if (adapterState != AvailabilityState.poweredOn) {
    try {
      await UniversalBle.enableBluetooth();
    } catch (e) {
      ToastUtils().showErrorToast(l10n.turnBLEOn);
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
