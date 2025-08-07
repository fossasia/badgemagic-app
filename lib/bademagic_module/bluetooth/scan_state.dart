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
    manager.clearConnectedDevice();
    await FlutterBluePlus.stopScan();

    toast.showToast("Searching for device...");
    Completer<BleState?> nextStateCompleter = Completer();
    StreamSubscription<List<ScanResult>>? subscription;

    bool isCompleted = false;
    try {
      subscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          if (isCompleted || results.isEmpty) return;

          try {
            final foundDevice = results.firstWhere(
              (r) => r.advertisementData.serviceUuids.contains(
                Guid("0000fee0-0000-1000-8000-00805f9b34fb"),
              ),
              orElse: () => throw Exception("Matching device not found."),
            );

            isCompleted = true;
            await FlutterBluePlus.stopScan();
            toast.showToast('Device found. Connecting...');
            nextStateCompleter.complete(
              ConnectState(scanResult: foundDevice, manager: manager),
            );
          } catch (_) {
            // Ignore and keep scanning
          }
        },
        onError: (e) {
          if (!isCompleted) {
            isCompleted = true;
            FlutterBluePlus.stopScan();
            logger.e("Scan error: $e");
            toast.showErrorToast('Scan error occurred.');
            nextStateCompleter.completeError(
              Exception("Error during scanning: $e"),
            );
          }
        },
      );

      await FlutterBluePlus.startScan(
        withServices: [Guid("0000fee0-0000-1000-8000-00805f9b34fb")],
        removeIfGone: const Duration(seconds: 5),
        continuousUpdates: true,
        timeout: const Duration(seconds: 15),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!isCompleted) {
        isCompleted = true;
        FlutterBluePlus.stopScan();
        toast.showErrorToast('Device not found.');
        nextStateCompleter.completeError(Exception('Device not found.'));
      }

      return await nextStateCompleter.future;
    } catch (e) {
      logger.e("Exception during scanning: $e");
      throw Exception("Please check if the device is turned on and retry.");
    } finally {
      await subscription?.cancel();
      await FlutterBluePlus.stopScan();
    }
  }
}
