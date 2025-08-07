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
    try {
      try {
        await scanResult.device.disconnect();
        logger.d("Pre-emptive disconnect for clean state");
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {
        logger.d("No existing connection to disconnect");
      }

      await scanResult.device.connect(autoConnect: false);
      BluetoothConnectionState connectionState =
          await scanResult.device.connectionState.first;

      if (connectionState == BluetoothConnectionState.connected) {
        logger.d("Device connected successfully");
        toast.showToast('Device connected successfully.');

        manager.connectedDevice = scanResult.device;

        final writeState = WriteState(
          device: scanResult.device,
          manager: manager,
        );

        return await writeState.process();
      } else {
        throw Exception("Failed to connect to the device");
      }
    } catch (e) {
      toast.showErrorToast('Failed to connect. Retrying...');
      rethrow;
    }
  }
}
