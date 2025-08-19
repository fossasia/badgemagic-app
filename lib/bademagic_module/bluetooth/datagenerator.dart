import 'package:badgemagic/bademagic_module/models/data.dart';
import 'package:badgemagic/bademagic_module/utils/data_to_bytearray_converter.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';

class DataTransferManager {
  final Data data;

  BluetoothDevice? connectedDevice;

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
