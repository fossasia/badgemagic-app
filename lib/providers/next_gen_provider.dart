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
      print("Starting clean connection for device: $deviceId");
      try {
        await UniversalBle.disconnect(deviceId);
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {}

      await UniversalBle.connect(deviceId);
      final connectionState = await UniversalBle.getConnectionState(deviceId);

      if (connectionState == BleConnectionState.connected) {
        print("NextGen device connected");
        connectedDevice = device;
        await UniversalBle.discoverServices(deviceId);
        listenToResponses(deviceId);
        return true;
      }
      return false;
    } catch (e) {
      print("Connection error: $e");
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
      print("NextGen notifications enabled");
    } catch (e) {
      print("Notification error: $e");
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
        print("Response stream error: $error");
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
      print("Command sent: $command");
    } catch (e) {
      print("Send error: $e");
      rethrow;
    }
  }

  // POWER SETTING (0x01)
  Future<void> powerOff(String deviceId) async {
    await sendCommand(deviceId, [0x01, 0x00]);
  }

  Future<void> enableResetAfterUpload(String deviceId) async {
    await sendCommand(deviceId, [0x01, 0x01, 0x00]);
    await saveCfg(deviceId);
  }

  Future<void> disableResetAfterUpload(String deviceId) async {
    await sendCommand(deviceId, [0x01, 0x01, 0x01]);
    await saveCfg(deviceId);
  }

  // STREAMING SETTING (0x02)
  Future<void> enterStreamingMode(String deviceId) async {
    await sendCommand(deviceId, [0x02, 0x00]);
  }

  Future<void> exitStreamingMode(String deviceId) async {
    await sendCommand(deviceId, [0x02, 0x01]);
  }

  // STREAM BITMAP (0x03)
  Future<void> streamBitmap(String deviceId, List<int> columnWords) async {
    if (columnWords.length > 44) {
      throw Exception("Maximum 44 columns for 11x44 display");
    }

    List<int> command = [0x03];
    for (int word in columnWords) {
      command.add((word >> 8) & 0xFF);  // High byte
      command.add(word & 0xFF);          // Low byte
    }
    await sendCommand(deviceId, command);
  }

  // BLE SETTING (0x04)
  Future<void> enableAlwaysOnBLE(String deviceId) async {
    await sendCommand(deviceId, [0x04, 0x00, 0x01]);
    await saveCfg(deviceId);
  }

  Future<void> disableAlwaysOnBLE(String deviceId) async {
    await sendCommand(deviceId, [0x04, 0x00, 0x00]);
    await saveCfg(deviceId);
  }

  Future<void> changeBLEName(String deviceId, String newName) async {
    if (newName.length > 20) {
      throw Exception("Name must be <= 20 characters");
    }
    List<int> command = [0x04, 0x01];
    command.addAll(newName.codeUnits);
    await sendCommand(deviceId, command);
    await saveCfg(deviceId);
  }

  // FLASH SPLASH SCREEN (0x05)
  Future<void> flashSplashScreen(
      String deviceId,
      int width,
      int height,
      int frameHeight,
      List<int> pixelDataXBM,
      ) async {
    if (width > 48) throw Exception("Width must be <= 48 pixels");
    if (height > 44) throw Exception("Height must be <= 44 pixels");

    List<int> command = [0x05, width, height, frameHeight];
    command.addAll(pixelDataXBM);
    await sendCommand(deviceId, command);
  }

  // SAVE CONFIG (0x06) - MUST BE CALLED AFTER CONFIG CHANGES!
  Future<void> saveCfg(String deviceId) async {
    await sendCommand(deviceId, [0x06]);
  }

  // LOAD FALLBACK CONFIG (0x07)
  Future<void> loadFallbackCfg(String deviceId) async {
    await sendCommand(deviceId, [0x07]);
    await saveCfg(deviceId);
  }

  // MISCELLANEOUS CONFIGS (0x08)
  Future<void> adjustSplashScreenSpeed(String deviceId, int speedMs) async {
    if (speedMs < 10) throw Exception("Speed must be >= 10 ms");

    List<int> command = [
      0x08,
      0x00,
      (speedMs >> 8) & 0xFF,
      speedMs & 0xFF,
    ];
    await sendCommand(deviceId, command);
    await saveCfg(deviceId);
  }

  Future<void> adjustBrightness(String deviceId, int level) async {
    if (level < 0 || level > 3) {
      throw Exception("Brightness must be 0-3");
    }
    await sendCommand(deviceId, [0x08, 0x01, level]);
    await saveCfg(deviceId);
  }

  void _handleErrorCode(int code) {
    switch (code) {
      case 0x00: print("✓ Success"); break;
      case 0xFF: print("✗ Parameters out of range"); break;
      case 0xFE: print("✗ Height > 44 pixels"); break;
      case 0xFD: print("✗ Message length not matched"); break;
      case 0xFC: print("✗ Missing pixel contents"); break;
      case 0x01: print("✗ Flash writing error"); break;
      case 0x02: print("✗ Value out of allowed range"); break;
      default: print("✗ Unknown error: 0x${code.toRadixString(16).padLeft(2, '0')}");
    }
  }

  void dispose() {
    _responseSubscription?.cancel();
  }
}