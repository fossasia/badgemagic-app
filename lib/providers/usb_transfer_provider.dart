import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hid_tool/hid_tool.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';

enum UsbConnectionType { none, hid }

class UsbTransferProvider with ChangeNotifier {
  static const int _badgeVendorId = 0x0416;
  static const int _badgeProductId = 0x5020;

  UsbConnectionType _connectionType = UsbConnectionType.none;
  bool get isConnected => _connectionType != UsbConnectionType.none;
  UsbConnectionType get connectionType => _connectionType;

  HidDevice? _activeHidDevice;

  StreamSubscription<HidDeviceEvent>? _attachSubscription;
  StreamSubscription<HidDeviceEvent>? _detachSubscription;
  bool _prewarming = false;
  bool _permissionPrewarmed = false;

  Future<void> startUsbMonitoring() async {
    if (!Platform.isAndroid) return;
    if (_attachSubscription != null) return;
    await HidDeviceEvents.startListening();
    _attachSubscription = HidDeviceEvents.onConnected.listen((event) {
      if (event.vendorId == _badgeVendorId &&
          event.productId == _badgeProductId) {
        _prewarmPermission();
      }
    });
    _detachSubscription = HidDeviceEvents.onDisconnected.listen((event) {
      if (event.vendorId == _badgeVendorId &&
          event.productId == _badgeProductId) {
        _permissionPrewarmed = false;
      }
    });
  }

  Future<void> _prewarmPermission() async {
    if (_prewarming || _permissionPrewarmed || isConnected) return;
    _prewarming = true;
    try {
      final devices = await Hid.getDevices(
          vendorId: _badgeVendorId, productId: _badgeProductId);
      if (devices.isEmpty) return;
      final device = devices.first;
      await device.open();
      if (device.isOpen) {
        _permissionPrewarmed = true;
        await device.close();
      }
    } catch (e) {
      debugPrint("USB permission pre-warm skipped: $e");
    } finally {
      _prewarming = false;
    }
  }

  Future<bool> connectHid({bool silent = false}) async {
    await disconnectUsb();
    try {
      final availableDevices = await Hid.getDevices(
          vendorId: _badgeVendorId, productId: _badgeProductId);

      if (availableDevices.isEmpty) {
        if (!silent) ToastUtils().showErrorToast("No USB HID device detected.");
        return false;
      }

      final targetDevice = availableDevices.first;
      await targetDevice.open();

      if (!targetDevice.isOpen) {
        if (!silent) ToastUtils().showErrorToast("Error opening HID device.");
        return false;
      }

      _activeHidDevice = targetDevice;
      _connectionType = UsbConnectionType.hid;
      notifyListeners();

      if (!silent) {
        ToastUtils().showToast("Badge successfully connected via USB (HID)!");
      }
      return true;
    } catch (e) {
      debugPrint("HID connection error: $e");
      if (!silent) ToastUtils().showErrorToast("HID Connection error: $e");
      await disconnectUsb();
      return false;
    }
  }

  Future<bool> writeBytes(List<int> bytes, {bool silent = false}) async {
    if (!isConnected) {
      if (!silent) ToastUtils().showErrorToast("No badge connected via USB.");
      return false;
    }

    try {
      const int hidDataChunkSize = 64;

      for (int i = 0; i < bytes.length; i += hidDataChunkSize) {
        int end = (i + hidDataChunkSize < bytes.length)
            ? i + hidDataChunkSize
            : bytes.length;
        List<int> chunk = bytes.sublist(i, end);

        if (chunk.length < hidDataChunkSize) {
          chunk = List<int>.from(chunk)
            ..addAll(List<int>.filled(hidDataChunkSize - chunk.length, 0));
        }

        if (Platform.isAndroid) {
          await _activeHidDevice!.sendReport(
            Uint8List.fromList(chunk.sublist(1)),
            reportId: chunk[0],
          );
        } else {
          await _activeHidDevice!
              .sendReport(Uint8List.fromList(chunk), reportId: 0x00);
        }

        await Future.delayed(const Duration(milliseconds: 50));
      }

      debugPrint("USB HID write completed successfully.");
      return true;
    } catch (e) {
      debugPrint("Error writing data: $e");
      if (!silent) ToastUtils().showErrorToast("USB data transmission error.");
      return false;
    }
  }

  Future<void> disconnectUsb() async {
    if (_activeHidDevice != null) {
      try {
        await _activeHidDevice!.close();
      } catch (e) {
        debugPrint("Error releasing HID device: $e");
      }
      _activeHidDevice = null;
    }

    _connectionType = UsbConnectionType.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _attachSubscription?.cancel();
    _detachSubscription?.cancel();
    disconnectUsb();
    super.dispose();
  }
}
