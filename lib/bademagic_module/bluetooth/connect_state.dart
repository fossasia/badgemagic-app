import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/write_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';

class ConnectState extends RetryBleState {
  final ScanResult scanResult;
  final DataTransferManager manager;

  ConnectState({required this.manager, required this.scanResult});

  @override
  Future<BleState?> processState() async {
    bool connected = false;

    try {
      await scanResult.device.connect(autoConnect: false);
      BluetoothConnectionState connectionState =
          await scanResult.device.connectionState.first;

      if (connectionState == BluetoothConnectionState.connected) {
        connected = true;

        logger.d("Device connected");
        toast.showToast('Device connected successfully.');

        return WriteState(device: scanResult.device, manager: manager);
      } else {
        throw Exception("Failed to connect to the device");
      }
    } catch (e) {
      toast.showErrorToast('Failed to connect retrying...');
      rethrow;
    } finally {
      if (!connected) {
        await scanResult.device.disconnect();
      }
    }
  }
}
