import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hid_tool/hid_tool.dart';
import 'package:flserial/flserial.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';

enum UsbConnectionType { none, serial, hid }

class UsbTransferProvider with ChangeNotifier {
  UsbConnectionType _connectionType = UsbConnectionType.none;
  bool get isConnected => _connectionType != UsbConnectionType.none;
  UsbConnectionType get connectionType => _connectionType;

  FlSerial? _activeSerial;
  StreamSubscription<SerialEvent>? _serialRxSubscription;

  HidDevice? _activeHidDevice;

  Future<bool> connectSerial({bool silent = false}) async {
    await disconnectUsb();
    try {
      final ports = await FlSerial.availablePorts();

      if (ports.isEmpty) {
        if (!silent) ToastUtils().showErrorToast("No USB COM device detected.");
        return false;
      }

      final targetPort = ports.first;
      _activeSerial = FlSerial();

      _serialRxSubscription = _activeSerial!.events.listen((event) {
        switch (event.type) {
          case SerialEventType.connected:
            debugPrint("USB COM: Port opened");
            break;
          case SerialEventType.data:
            debugPrint(
                "USB COM Rx: ${String.fromCharCodes(event.data as Uint8List)}");
            break;
          case SerialEventType.disconnected:
            debugPrint("USB COM: Port closed/disconnected");
            disconnectUsb();
            break;
          default:
            break;
        }
      });

      final config = SerialConfig(baudRate: 115200);
      final ok = await _activeSerial!.open(targetPort.path, config);

      if (!ok) {
        if (!silent) ToastUtils().showErrorToast("Error opening COM port.");
        return false;
      }

      _connectionType = UsbConnectionType.serial;
      notifyListeners();

      if (!silent) {
        ToastUtils().showToast("Badge successfully connected via USB (COM)!");
      }
      return true;
    } catch (e) {
      debugPrint("COM connection error: $e");
      if (!silent) ToastUtils().showErrorToast("Connection error: $e");
      await disconnectUsb();
      return false;
    }
  }

  Future<bool> connectHid({bool silent = false}) async {
    await disconnectUsb();
    try {
      final availableDevices =
          await Hid.getDevices(vendorId: 0x0416, productId: 0x5020);

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
      final uint8list = Uint8List.fromList(bytes);

      if (_connectionType == UsbConnectionType.serial) {
        _activeSerial!.write(uint8list);
        debugPrint(
            "USB COM write completed successfully (${uint8list.length} bytes sent).");
        return true;
      } else if (_connectionType == UsbConnectionType.hid) {
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
      }
    } catch (e) {
      debugPrint("Error writing data: $e");
      if (!silent) ToastUtils().showErrorToast("USB data transmission error.");
      return false;
    }
    return false;
  }

  Future<void> disconnectUsb() async {
    _serialRxSubscription?.cancel();
    _serialRxSubscription = null;
    if (_activeSerial != null) {
      try {
        await _activeSerial!.close();
        await _activeSerial!.dispose();
      } catch (e) {
        debugPrint("Error releasing serial port: $e");
      }
      _activeSerial = null;
    }

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
    disconnectUsb();
    super.dispose();
  }
}
