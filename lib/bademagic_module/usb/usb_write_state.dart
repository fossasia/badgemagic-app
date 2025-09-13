import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/completed_state.dart';
import 'package:badgemagic/bademagic_module/usb/payload_builder.dart';
import 'package:badgemagic/bademagic_module/usb/usb_cdc.dart';

/// USB transfer state (mirrors WriteState for BLE)
class UsbWriteState extends NormalBleState {
  final PayloadBuilder builder;

  UsbWriteState({required this.builder});

  @override
  Future<BleState?> processState() async {
    final usb = UsbCdc();
    try {
      // Open the device
      final opened = await usb.openDevice();
      if (!opened) {
        throw Exception("No BadgeMagic USB device found");
      }

      // Build payload
      final dataChunks = await builder.buildPayloads();
      logger.d("USB payload chunks: ${dataChunks.length}");

      // Write each chunk with retries
      for (final chunk in dataChunks) {
        bool success = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            await usb.write(chunk);
            logger.d("USB chunk written: $chunk");
            success = true;
            break;
          } catch (e) {
            logger.e("USB write failed (attempt $attempt/3): $e");
          }
        }
        if (!success) {
          throw Exception("Failed to transfer data over USB");
        }
        await Future.delayed(const Duration(milliseconds: 20));
      }

      return CompletedState(isSuccess: true, message: "USB transfer complete");
    } catch (e) {
      logger.e("USB transfer error: $e");
      throw Exception("USB transfer failed: $e");
    } finally {
      await usb.close();
    }
  }
}
