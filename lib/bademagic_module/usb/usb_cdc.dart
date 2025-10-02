import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:usb_serial/usb_serial.dart';

/// Wrapper around usb_serial for BadgeMagic devices
class UsbCdc {
  final logger = Logger();
  UsbPort? _port;

  // FOSSASIA BadgeMagic Device IDs - BOTH MODES
  static const int normalVendorId = 4348; // 0x10FC - Normal mode
  static const int normalProductId = 55200; // 0x55E0 - Normal mode
  static const int bootloaderVendorId = 1046; // 0x0416 - Bootloader mode
  static const int bootloaderProductId = 20512; // 0x5020 - Bootloader mode

  /// Open the first available FOSSASIA USB device
  Future<bool> openDevice() async {
    final devices = await listDevices();

    // Filter for FOSSASIA badges - BOTH MODES
    final fossasiaDevices = devices
        .where((device) =>
            (device.vid == normalVendorId && device.pid == normalProductId) ||
            (device.vid == bootloaderVendorId &&
                device.pid == bootloaderProductId))
        .toList();

    if (fossasiaDevices.isEmpty) {
      logger.e("No FOSSASIA badge found. Available devices: $devices");
      return false;
    }

    final device = fossasiaDevices.first;
    logger.d("Found FOSSASIA device: ${device.vid}:${device.pid}");

    // BOOTLOADER DETECTION
    if (device.vid == bootloaderVendorId && device.pid == bootloaderProductId) {
      logger.e("Device is in bootloader mode - cannot transfer data");
      throw Exception(
          "Device is in bootloader mode. Please disconnect, then connect without holding any buttons.");
    }

    _port = await device.create();
    if (_port == null) {
      logger.e("Failed to create USB port");
      return false;
    }

    final opened = await _port!.open();
    if (!opened) {
      logger.e("Failed to open USB port");
      return false;
    }

    await _port!.setPortParameters(
      115200,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    logger.d("USB device opened successfully");
    return true;
  }

  /// Write data to the USB port
  Future<void> write(List<int> data) async {
    if (_port == null) throw Exception("USB port not open");

    try {
      await _port!.write(Uint8List.fromList(data));
      logger.d("USB chunk written: ${data.length} bytes");
    } catch (e) {
      logger.e("Failed to write USB chunk: $e");
      rethrow;
    }
  }

  /// Close the USB port
  Future<void> close() async {
    try {
      await _port?.close();
      logger.d("USB port closed");
    } catch (e) {
      logger.e("Error closing USB port: $e");
    }
  }

  /// List connected USB devices with better logging
  Future<List<UsbDevice>> listDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      logger.d(
          "USB devices found: ${devices.map((d) => 'VID:${d.vid?.toRadixString(16)} PID:${d.pid?.toRadixString(16)}').toList()}");
      return devices;
    } catch (e) {
      logger.e("Error listing USB devices: $e");
      return [];
    }
  }

  /// Helper to check if any FOSSASIA device is connected
  Future<bool> isFossasiaDeviceConnected() async {
    final devices = await listDevices();
    return devices.any((device) =>
        (device.vid == normalVendorId && device.pid == normalProductId) ||
        (device.vid == bootloaderVendorId &&
            device.pid == bootloaderProductId));
  }
}
