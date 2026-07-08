import 'dart:async';
import 'dart:typed_data';
import 'package:universal_ble/universal_ble.dart';
import '../globals/globals.dart';


class NextGenBLEManager {
  StreamSubscription<Uint8List>? _responseSubscription;
  BleDevice? connectedDevice;

  Future<bool> connectToNextGenDevice(BleDevice device) async {
    final deviceId = device.deviceId;
    try {
      print("Avvio connessione pulita per device: $deviceId");

      try {
        await UniversalBle.disconnect(deviceId);
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {}

      await UniversalBle.connect(deviceId);
      final connectionState = await UniversalBle.getConnectionState(deviceId);

      if (connectionState == BleConnectionState.connected) {
        print("Device connesso all'hardware NextGen.");
        connectedDevice = device;

        await UniversalBle.discoverServices(deviceId);

        if (connectionState == BleConnectionState.connected) {
          print("Device connesso all'hardware NextGen.");
          connectedDevice = device;

          await UniversalBle.discoverServices(deviceId);

          listenToResponses(deviceId);

          return true;
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Errore durante la connessione NextGen: $e");
      return false;
    }
  }

  Future<void> enableNotifications(String deviceId) async {
    try {
      await UniversalBle.subscribeNotifications(
        deviceId,
        NEXTGEN_SERVICE_UUID,
        NEXTGEN_NOTIFY_CHAR,
      );
      print("Notifiche NextGen attivate sulla caratteristica.");
    } catch (e) {
      print("Errore attivazione notifiche: $e");
    }
  }

  void listenToResponses(String deviceId) async {
    _responseSubscription?.cancel();

    await enableNotifications(deviceId);


    _responseSubscription = UniversalBle.characteristicValueStream(
      deviceId,
      NEXTGEN_NOTIFY_CHAR,
    ).listen(
          (Uint8List data) {
        if (data.isNotEmpty) {
          int errorCode = data[0];
          _handleErrorCode(errorCode);
        }
      },
      onError: (error) {
        print("Errore nello stream di risposta NextGen: $error");
      },
    );
  }


  Future<void> sendCommand(String deviceId, List<int> command) async {
    try {
      await UniversalBle.write(
        deviceId,
        NEXTGEN_SERVICE_UUID,
        NEXTGEN_WRITE_CHAR,
        Uint8List.fromList(command),
        withoutResponse: false,
      );
      print("command sent: $command");
    } catch (e) {
      print("error duting send command: $e");
      rethrow;
    }
  }

  Future<void> powerOff(String deviceId) async {
    await sendCommand(deviceId, [0x01, 0x00]);
  }

  Future<void> enterStreamingMode(String deviceId) async {
    await sendCommand(deviceId, [0x02, 0x00]);
  }

  Future<void> exitStreamingMode(String deviceId) async {
    await sendCommand(deviceId, [0x02, 0x01]);
  }

  Future<void> streamBitmap(String deviceId, List<int> bitmapWords) async {
    List<int> command = [0x03];
    command.addAll(bitmapWords);
    await sendCommand(deviceId, command);
  }

  Future<void> adjustBrightness(String deviceId, int level) async {
    if (level < 0 || level > 3) return;
    await sendCommand(deviceId, [0x08, 0x01, level]);
  }

  void _handleErrorCode(int code) {
    switch (code) {
      case 0x00: print("✓ Success"); break;
      case 0xFF: print("✗ Parameters out of range"); break;
      case 0xFE: print("✗ Height larger than maximum"); break;
      case 0xFD: print("✗ Message length not matched"); break;
      case 0xFC: print("✗ Missing pixel contents"); break;
      case 0x01: print("✗ Flash writing error"); break;
      case 0x02: print("✗ Value out of allowed range"); break;
      default: print("✗ Unknown error code: $code");
    }
  }

  void dispose() {
    _responseSubscription?.cancel();
  }
}