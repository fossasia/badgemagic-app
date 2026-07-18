import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/bluetooth/scan_state.dart';
import 'package:badgemagic/bademagic_module/transport/badge_transport.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:universal_ble/universal_ble.dart';

class BleBadgeTransport extends BadgeTransport {
  final BadgeScanMode mode;
  final List<String> allowedNames;

  BleBadgeTransport({
    this.mode = BadgeScanMode.any,
    this.allowedNames = const <String>[],
  });

  @override
  BadgeTransportType get type => BadgeTransportType.bluetooth;

  @override
  Future<bool> isAvailable() async {
    final state = await UniversalBle.getBluetoothAvailabilityState();
    return state != AvailabilityState.unsupported;
  }

  @override
  Future<void> send(DataTransferManager manager) async {
    BleState? state = ScanState(
      manager: manager,
      mode: mode,
      allowedNames: allowedNames,
    );

    while (state != null) {
      state = await state.process();
    }
  }
}
