import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:get_it/get_it.dart';

import '../utils/toast_utils.dart';

Future<bool> checkAdapterState() async {
  final adapterState = await UniversalBle.getBluetoothAvailabilityState();
  if (adapterState != AvailabilityState.poweredOn) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
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
