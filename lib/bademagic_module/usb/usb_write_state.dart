import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';
import 'package:badgemagic/bademagic_module/bluetooth/completed_state.dart';
import 'package:badgemagic/bademagic_module/usb/payload_builder.dart';
import 'package:badgemagic/bademagic_module/usb/usb_cdc.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb, Platform checks
import 'dart:io' show Platform;
import 'package:flutter/services.dart'; // for MissingPluginException

class UsbWriteState extends NormalBleState {
  final PayloadBuilder builder;

  UsbWriteState({required this.builder});

  @override
  Future<BleState?> processState() async {
    // Unsupported platforms (macOS, Web, etc.)
    if (!kIsWeb && !Platform.isAndroid) {
      toast.showErrorToast("USB transfer not supported on this platform");
      return CompletedState(isSuccess: false, message: "Unsupported platform");
    }

    final usb = UsbCdc();
    try {
      bool opened;
      try {
        opened = await usb.openDevice();
      } on MissingPluginException catch (_) {
        toast.showErrorToast(
          "USB plugin not available. Please ensure the plugin is installed and platform supports USB.",
        );
        throw Exception("USB plugin missing or not registered");
      }

      if (!opened) {
        toast.showErrorToast("No BadgeMagic USB device found");
        throw Exception("No USB device connected");
      }

      final dataChunks = await builder.buildPayloads();
      logger.d("USB payload chunks: ${dataChunks.length}");

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
          toast.showErrorToast("Failed to transfer data over USB");
          throw Exception("USB transfer failed");
        }
        await Future.delayed(const Duration(milliseconds: 20));
      }

      toast.showToast("USB transfer completed successfully");
      return CompletedState(isSuccess: true, message: "USB transfer complete");
    } catch (e) {
      logger.e("USB transfer error: $e");
      if (e.toString().contains("MissingPluginException")) {
        // Already handled above; no need to show extra toast
      } else if (e.toString().contains("No USB device connected")) {
        // Already shown toast above
      } else {
        toast.showErrorToast("USB transfer failed: ${e.toString()}");
      }
      throw e;
    } finally {
      await usb.close();
    }
  }
}
