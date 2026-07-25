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

  /// Whether [device] is a badge this scan should connect to.
  ///
  /// Two independent questions, deliberately kept apart:
  ///
  /// 1. Does it look like a badge at all? Satisfied by the advertised service
  ///    UUID **or** the advertised name. These are OR'd because OEM firmware
  ///    advertises no service UUIDs, while the open firmware's name is
  ///    user-changeable - requiring both would exclude one or the other.
  /// 2. Does it pass the user's badge-selection setting? Only consulted in
  ///    [BadgeScanMode.specific], and matched on the full name, lower-cased.
  bool _isTargetBadge(BleDevice device) {
    // device.services holds what the advertisement carried, not the full GATT
    // table, so OEM badges contribute nothing here and rely on the name.
    final looksLikeBadge = device.services.contains(targetServiceUuid) ||
        matchesBadgeName(device.name);

    if (!looksLikeBadge) return false;
    if (mode == BadgeScanMode.any) return true;

    final deviceName = (device.name ?? '').trim().toLowerCase();
    return allowedNames
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .contains(deviceName);
  }

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
            if (_isTargetBadge(device)) {
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

      // Supplying withNamePrefix switches universal_ble into custom-filter
      // mode, where the *native* scanner runs unfiltered and matching happens
      // in the plugin with OR semantics across filter kinds. That is what lets
      // OEM badges - which advertise no service UUIDs - be seen at all, and it
      // mirrors what the stock vendor app does.
      await UniversalBle.startScan(
        scanFilter: ScanFilter(
          withServices: [targetServiceUuid],
          withNamePrefix: badgeNamePrefixes,
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
