import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';

class UsbTransferProvider with ChangeNotifier {
  SerialPort? _activePort;
  SerialPortReader? _portReader;
  StreamSubscription<Uint8List>? _rxSubscription;
  bool _isConnected = false;
  String? _connectedPortName;

  bool get isConnected => _isConnected;
  String? get connectedPortName => _connectedPortName;

  Future<bool> connectUsb() async {
    try {
      final availablePorts = SerialPort.availablePorts;

      if (availablePorts.isEmpty) {
        ToastUtils().showErrorToast(
            "No USB serial device detected. Please check the OTG connection.");
        return false;
      }

      String? targetPortName;

      for (final name in availablePorts) {
        final port = SerialPort(name);
        try {
          final vid = port.vendorId;
          final pid = port.productId;
          debugPrint(
              "Port found: $name - VID: 0x${vid?.toRadixString(16)}, PID: 0x${pid?.toRadixString(16)}");

          if (vid == 0x0416) {
            targetPortName = name;
            break;
          }
        } catch (e) {
          debugPrint("Unreadable info on port $name: $e");
        }
      }

      targetPortName ??= availablePorts.first;

      final port = SerialPort(targetPortName);

      if (!port.openReadWrite()) {
        final lastError = SerialPort.lastError;
        ToastUtils().showErrorToast("Error opening port: $lastError");
        return false;
      }

      final config = SerialPortConfig()
        ..baudRate = 115200 //WARNING: do not touch this value
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);

      port.config = config;

      _activePort = port;
      _connectedPortName = targetPortName;
      _isConnected = true;
      notifyListeners();

      _portReader = SerialPortReader(port);
      _rxSubscription = _portReader!.stream.listen((Uint8List data) {
        final message = String.fromCharCodes(data);
        debugPrint("USB Rx (Badge): $message");
      }, onError: (error) {
        debugPrint("Error during serial read: $error");
        disconnectUsb();
      });

      ToastUtils().showToast("Badge successfully connected via USB serial!");
      return true;
    } catch (e) {
      debugPrint("Generic serial connection error: $e");
      ToastUtils().showErrorToast("Connection error: $e");
      disconnectUsb();
      return false;
    }
  }

  Future<bool> writeBytes(List<int> bytes) async {
    if (!_isConnected || _activePort == null) {
      ToastUtils().showErrorToast("No badge connected via USB.");
      return false;
    }

    try {
      final uint8list = Uint8List.fromList(bytes);

      final bytesWritten = _activePort!.write(uint8list, timeout: 2000);

      if (bytesWritten == uint8list.length) {
        debugPrint(
            "USB write completed successfully ($bytesWritten bytes sent).");
        return true;
      } else {
        debugPrint(
            "Partial write: only $bytesWritten of ${uint8list.length} bytes sent.");
        return false;
      }
    } catch (e) {
      debugPrint("Error writing to serial port: $e");
      ToastUtils().showErrorToast("USB data transmission error.");
      return false;
    }
  }

  void disconnectUsb() {
    _rxSubscription?.cancel();
    _rxSubscription = null;
    _portReader = null;

    if (_activePort != null) {
      try {
        _activePort!.close();
        _activePort!.dispose();
      } catch (e) {
        debugPrint("Error releasing serial port: $e");
      }
      _activePort = null;
    }

    _connectedPortName = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectUsb();
    super.dispose();
  }
}
