// lib/providers/transfer_provider.dart
import 'package:flutter/foundation.dart';
import 'package:badgemagic/constants.dart';

class TransferProvider with ChangeNotifier {
  ConnectionType? _selectedMethod;
  bool _showTray = false;

  ConnectionType? get selectedMethod => _selectedMethod;
  bool get showTray => _showTray;

  void openTray() {
    _showTray = true;
    notifyListeners();
  }

  void closeTray() {
    _showTray = false;
    notifyListeners();
  }

  void selectMethod(ConnectionType method) {
    _selectedMethod = method;
    _showTray = false;
    notifyListeners();
  }

  void reset() {
    _selectedMethod = null;
    _showTray = false;
    notifyListeners();
  }
}
