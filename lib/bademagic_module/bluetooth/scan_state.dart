import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/connect_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'base_ble_state.dart';

class ScanState extends NormalBleState {
  final DataTransferManager manager;
  ScanState({required this.manager});

  @override
  Future<BleState?> processState() async {
    StreamSubscription<List<ScanResult>>? subscription;
    toast.showToast("Searching for device...");

    Completer<BleState?> nextStateCompleter = Completer();
    bool isCompleted = false;

    ScanResult? foundDevice;

    try {
      subscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          if (!isCompleted) {
            if (results.isNotEmpty) {
              foundDevice = results.firstWhere(
                (result) => result.advertisementData.serviceUuids
                    .contains(Guid("0000fee0-0000-1000-8000-00805f9b34fb")),
              );
              if (foundDevice != null) {
                toast.showToast('Device found. Connecting...');
                isCompleted = true;
                nextStateCompleter.complete(ConnectState(
                  scanResult: foundDevice!,
                  manager: manager,
                ));
              }
            }
          }
        },
        onError: (e) async {
          if (!isCompleted) {
            isCompleted = true;
            logger.e("Scan error: $e");
            toast.showErrorToast('Scan error occurred.');
            nextStateCompleter.completeError(e);
          }
        },
      );

      await FlutterBluePlus.startScan(
        withServices: [Guid("0000fee0-0000-1000-8000-00805f9b34fb")],
        timeout: const Duration(seconds: 15), // Reduced scan timeout
      );

      await Future.delayed(const Duration(seconds: 1));

      // If no device is found after the scan timeout, complete with an error.
      if (!isCompleted) {
        toast.showToast('Device not found.');
        nextStateCompleter.completeError(Exception('Device not found.'));
      }

      return await nextStateCompleter.future;
    } catch (e) {
      logger.e("Exception during scanning: $e");
      throw Exception("please check the device is turned on and retry.");
    } finally {
      await subscription?.cancel();
    }
  }
}
