import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:usb_serial/usb_serial.dart';

/// Wrapper around usb_serial for BadgeMagic devices
class UsbCdc {
  final logger = Logger();
  UsbPort? _port;

  /// Open the first available USB device
  Future<bool> openDevice() async {
    final devices = await listDevices();

      // Filter for FOSSASIA badges
  final fossasiaDevices = devices.where((device) =>
    device.vid == 0x0416 && device.pid == 0x5020).toList();

    if (fossasiaDevices.isEmpty) {
    logger.e("No FOSSASIA badge found");
    return false;
  }

      final device = fossasiaDevices.first; // pick the first device
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

  /// New helper: list connected USB devices
  Future<List<UsbDevice>> listDevices() async {
    final devices = await UsbSerial.listDevices();
    logger.d("Listing USB devices: $devices");
    return devices;
  }
}

