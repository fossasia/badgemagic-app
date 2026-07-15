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
            "Nessun dispositivo USB seriale rilevato. Verifica la connessione OTG.");
        return false;
      }

      String? targetPortName;

      for (final name in availablePorts) {
        final port = SerialPort(name);
        try {
          final vid = port.vendorId;
          final pid = port.productId;
          debugPrint(
              "Porta trovata: $name - VID: 0x${vid?.toRadixString(16)}, PID: 0x${pid?.toRadixString(16)}");

          if (vid == 0x1A86) {
            targetPortName = name;
            break;
          }
        } catch (e) {
          debugPrint("Impossibile leggere le info per la porta $name: $e");
        }
      }

      targetPortName ??= availablePorts.first;

      final port = SerialPort(targetPortName);

      if (!port.openReadWrite()) {
        final lastError = SerialPort.lastError;
        ToastUtils().showErrorToast("Errore di apertura porta: $lastError");
        return false;
      }

      final config = SerialPortConfig()
        ..baudRate = 115200
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
        debugPrint("Errore durante la lettura seriale: $error");
        disconnectUsb();
      });

      ToastUtils().showToast("Badge connesso con successo via USB seriale!");
      return true;
    } catch (e) {
      debugPrint("Errore generico di connessione seriale: $e");
      ToastUtils().showErrorToast("Errore di connessione: $e");
      disconnectUsb();
      return false;
    }
  }

  Future<bool> writeBytes(List<int> bytes) async {
    if (!_isConnected || _activePort == null) {
      ToastUtils().showErrorToast("Nessun badge connesso via USB.");
      return false;
    }

    try {
      final uint8list = Uint8List.fromList(bytes);

      // La scrittura restituisce il numero di byte effettivamente scritti
      final bytesWritten = _activePort!.write(uint8list, timeout: 2000);

      if (bytesWritten == uint8list.length) {
        debugPrint(
            "Scrittura USB completata con successo ($bytesWritten byte inviati).");
        return true;
      } else {
        debugPrint(
            "Scrittura parziale: inviati solo $bytesWritten di ${uint8list.length} byte.");
        return false;
      }
    } catch (e) {
      debugPrint("Errore durante la scrittura sulla porta seriale: $e");
      ToastUtils().showErrorToast("Errore di trasmissione dati USB.");
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
        debugPrint("Errore durante il rilascio della porta seriale: $e");
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
