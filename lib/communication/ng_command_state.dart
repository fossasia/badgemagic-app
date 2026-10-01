import 'dart:async';
import 'dart:typed_data';
import 'package:badgemagic/others/globals.dart';
import 'package:universal_ble/universal_ble.dart';
import 'base_ble_state.dart';
import 'completed_state.dart';

class NgCommandState extends NormalBleState {
  final BleDevice device;
  final List<int> command;

  NgCommandState({required this.device, required this.command});

  @override
  Future<BleState?> processState() async {
    final deviceId = device.deviceId;
    final completer = Completer<int>();

    await UniversalBle.discoverServices(deviceId);

    await UniversalBle.setNotifiable(
      deviceId,
      ngServiceUuid,
      ngNotifyCharUuid,
      BleInputProperty.notification,
    );

    late final StreamSubscription sub;
    sub = UniversalBle.characteristicValueStream(deviceId, ngNotifyCharUuid)
        .listen(
      (Uint8List value) {
        if (!completer.isCompleted) {
          completer.complete(value.isNotEmpty ? value[0] : 0xff);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    try {
      await UniversalBle.write(
        deviceId,
        ngServiceUuid,
        ngWriteCharUuid,
        Uint8List.fromList(command),
        withoutResponse: false,
      );

      final code = await completer.future.timeout(const Duration(seconds: 5));

      if (code != 0x00) {
        throw Exception(
            "Command rejected by badge (code 0x${code.toRadixString(16)})");
      }

      return CompletedState(
          isSuccess: true, message: "Command executed", isNextGen: true);
    } finally {
      await sub.cancel();
    }
  }
}
