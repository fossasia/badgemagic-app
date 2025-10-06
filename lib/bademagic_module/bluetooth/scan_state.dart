import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/connect_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'base_ble_state.dart';

class ScanState extends NormalBleState {
  final DataTransferManager manager;
  final BadgeScanMode mode;
  final List<String> allowedNames;

  ScanState({
    required this.manager,
    required this.mode,
    required this.allowedNames,
  });

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
            final normalizedAllowedNames = allowedNames
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
                .toList();

            final foundDevice = results.firstWhere(
              (result) {
                final matchesUuid = result.advertisementData.serviceUuids
                    .contains(Guid("0000fee0-0000-1000-8000-00805f9b34fb"));

                final deviceName = result.device.name.trim().toLowerCase();
                final matchesName = mode == BadgeScanMode.any ||
                    normalizedAllowedNames.contains(deviceName);

                return matchesUuid && matchesName;
              },
              orElse: () => throw Exception("Matching device not found."),
            );

            isCompleted = true;
            FlutterBluePlus.stopScan();
            toast.showToast('Device found. Connecting...');

            nextStateCompleter.complete(ConnectState(
              scanResult: foundDevice,
              manager: manager,
            ));
          } catch (e) {
            logger.w("No matching device found in this batch: $e");
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
        removeIfGone: Duration(seconds: 5),
        continuousUpdates: true,
        timeout: const Duration(seconds: 15), // Reduced scan timeout.
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!isCompleted) {
        // If no devices found with service filter, try scanning all devices
        logger.d("No devices found with service filter, trying broad scan...");
        await FlutterBluePlus.stopScan();
        await Future.delayed(const Duration(milliseconds: 500));

        await FlutterBluePlus.startScan(
          removeIfGone: Duration(seconds: 5),
          continuousUpdates: true,
          timeout: const Duration(seconds: 5), // Shorter timeout for broad scan
        );

        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isCompleted) {
        // Try connecting to known devices by MAC address as fallback
        logger.d("No devices found via scanning, trying known devices...");
        final knownDeviceFound =
            await _tryKnownDevices(nextStateCompleter, isCompleted);

        if (!knownDeviceFound && !isCompleted) {
          isCompleted = true;
          FlutterBluePlus.stopScan();
          toast.showErrorToast('Device not found.');
          nextStateCompleter.completeError(Exception('Device not found.'));
        }
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

  Future<bool> _tryKnownDevices(
      Completer<BleState?> completer, bool isCompleted) async {
    final knownDevices = [
      '5C:53:10:B7:AC:F6',
    ];

    for (final macAddress in knownDevices) {
      if (isCompleted) break;

      try {
        logger.d("Trying to connect to known device: $macAddress");

        // Create a BluetoothDevice from MAC address
        final device = BluetoothDevice.fromId(macAddress);

        // Create a mock ScanResult for the known device
        final mockScanResult = ScanResult(
          device: device,
          advertisementData: AdvertisementData(
            advName:
                'LSLED', // Default name, will be updated if device has a name
            serviceUuids: [Guid("0000fee0-0000-1000-8000-00805f9b34fb")],
            txPowerLevel: 0,
            appearance: 0,
            manufacturerData: {},
            serviceData: {},
            connectable: true,
          ),
          rssi: -50,
          timeStamp: DateTime.now(),
        );

        logger.d("Created mock scan result for device: ${device.name}");

        // Try to connect to this device - only complete if not already completed
        if (!completer.isCompleted) {
          completer.complete(ConnectState(
            scanResult: mockScanResult,
            manager: manager,
          ));
          logger.d("Successfully initiated connection to known device");
          return true;
        } else {
          logger.d("Completer already completed, skipping");
        }
      } catch (e) {
        logger.w("Failed to connect to known device $macAddress: $e");
        continue;
      }
    }
    return false;
  }
}
