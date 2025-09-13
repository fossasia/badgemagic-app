import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:badgemagic/bademagic_module/usb/usb_serial.dart';

/// Wrapper around usb_serial for BadgeMagic devices
class UsbCdc {
  final logger = Logger();
  UsbPort? _port;

  /// Open the first available USB device
  Future<bool> openDevice() async {
    final devices = await UsbSerial.listDevices();
    logger.d("USB devices found: $devices");

    if (devices.isEmpty) {
      logger.e("No USB devices found");
      return false;
    }

    final device = devices.first; // pick the first device
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

    // Typical CDC ACM settings
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
}
