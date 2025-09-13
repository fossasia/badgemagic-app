// usb_scan_state.dart
import 'dart:async';
import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/usb/payload_builder.dart';
import 'package:badgemagic/bademagic_module/usb/usb_cdc.dart';
import 'package:badgemagic/bademagic_module/bluetooth/completed_state.dart';
import 'package:badgemagic/bademagic_module/usb/usb_write_state.dart';

/// USB scan state (mirrors ScanState for BLE)
class UsbScanState extends NormalBleState {
  final PayloadBuilder builder;

  UsbScanState({required this.builder});

  @override
  Future<BleState?> processState() async {
    final usb = UsbCdc();
    toast.showToast("Searching for USB device...");

    try {
      final devices = await usb.listDevices(); // wrapper for UsbSerial.listDevices()
      
      final fossasiaDevices = devices.where((device) =>
  device.vid == 0x0416 && device.pid == 0x5020).toList();

  if (fossasiaDevices.isEmpty) {
  toast.showErrorToast("No FOSSASIA badge found");
  return CompletedState(isSuccess: false, message: "No FOSSASIA USB device found");
}

      toast.showToast("USB device found. Preparing transfer...");

      // Directly pass to UsbWriteState
      final writeState = UsbWriteState(builder: builder);
      return await writeState.process();
    } catch (e) {
      logger.e("USB scan error: $e");
      toast.showErrorToast("USB scan failed: $e");
      return CompletedState(isSuccess: false, message: "USB scan failed: $e");
    }
  }
}
