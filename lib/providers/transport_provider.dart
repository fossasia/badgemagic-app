import 'package:badgemagic/bademagic_module/transport/badge_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransportProvider with ChangeNotifier {
  static const _prefsKey = 'badge_transport_type';

  BadgeTransportType _type = BadgeTransportType.bluetooth;
  bool _isLoaded = false;

  BadgeTransportType get transportType => _type;
  bool get isLoaded => _isLoaded;

  bool get usbSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  TransportProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefsKey);
    if (idx != null && idx >= 0 && idx < BadgeTransportType.values.length) {
      _type = BadgeTransportType.values[idx];
    }
    if (_type == BadgeTransportType.usb && !usbSupported) {
      _type = BadgeTransportType.bluetooth;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setTransportType(BadgeTransportType type) async {
    if (type == BadgeTransportType.usb && !usbSupported) return;
    _type = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, type.index);
    notifyListeners();
  }
}
