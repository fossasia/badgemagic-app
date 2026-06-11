import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/connect_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:universal_ble/universal_ble.dart';
import '../../globals/globals.dart';
import 'base_ble_state.dart';

class ScanState extends NormalBleState {
  final DataTransferManager manager;
  final BadgeScanMode mode;
  final List<String> allowedNames;

  final String targetServiceUuid = serviceUuid;

  ScanState({
    required this.manager,
    required this.mode,
    required this.allowedNames,
  });

  @override
  Future<BleState?> processState() async {
    manager.clearConnectedDevice();
    await UniversalBle.stopScan();

    toast.showToast("Searching for device...");
    Completer<BleState?> nextStateCompleter = Completer();
    StreamSubscription<BleDevice>? subscription;
    Timer? timeoutTimer;

    bool isCompleted = false;
    try {
      subscription = UniversalBle.scanStream.listen(
        (device) async {
          if (isCompleted) return;

          try {
            final normalizedAllowedNames = allowedNames
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toList();

            final matchesUuid = device.services.contains(targetServiceUuid);

            final deviceName = (device.name ?? "").trim().toLowerCase();
            final matchesName = mode == BadgeScanMode.any ||
                normalizedAllowedNames.contains(deviceName);

            if (matchesUuid && matchesName) {
              isCompleted = true;
              timeoutTimer?.cancel();
              await UniversalBle.stopScan();
              toast.showToast('Device found. Connecting...');

              nextStateCompleter.complete(ConnectState(
                scanResult: device,
                manager: manager,
              ));
            }
          } catch (e) {
            logger.w("Device discovered but filtered out: $e");
          }
        },
        onError: (e) {
          if (!isCompleted) {
            isCompleted = true;
            timeoutTimer?.cancel();
            UniversalBle.stopScan();
            logger.e("Scan error: $e");
            toast.showErrorToast('Scan error occurred.');
            nextStateCompleter.completeError(
              Exception("Error during scanning: $e"),
            );
          }
        },
      );

      await UniversalBle.startScan(
        scanFilter: ScanFilter(
          withServices: [targetServiceUuid],
        ),
      );

      timeoutTimer = Timer(const Duration(seconds: 15), () async {
        if (!isCompleted) {
          isCompleted = true;
          await UniversalBle.stopScan();
          toast.showErrorToast('Device not found.');
          nextStateCompleter.completeError(Exception('Device not found.'));
        }
      });

      return await nextStateCompleter.future;
    } catch (e) {
      timeoutTimer?.cancel();
      logger.e("Exception during scanning: $e");
      throw Exception("Please check if the device is turned on and retry.");
    } finally {
      await subscription?.cancel();
      await UniversalBle.stopScan();
    }
  }
}
