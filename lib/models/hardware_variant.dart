enum HardwareVariant {
  usbC4Key,
  microUsb4Key,
  usbC2Key,
  microUsb2Key,
}

extension HardwareVariantX on HardwareVariant {
  String get label {
    switch (this) {
      case HardwareVariant.usbC4Key:
        return '4 buttons USB-C';
      case HardwareVariant.microUsb4Key:
        return '4 buttons USB-Micro';
      case HardwareVariant.usbC2Key:
        return '2 buttons USB-C';
      case HardwareVariant.microUsb2Key:
        return '2 buttons USB-Micro';
    }
  }

  String? get _assetKeyword {
    switch (this) {
      case HardwareVariant.usbC4Key:
        return 'usb-c-4key';
      case HardwareVariant.microUsb4Key:
        return 'micro-b-4key';
      case HardwareVariant.usbC2Key:
        return 'usb-c-2key';
      case HardwareVariant.microUsb2Key:
        return 'micro-b-2key';
    }
  }

  static const List<String> _allKeywords = [
    'usb-c-4key',
    'micro-b-4key',
    'usb-c-2key',
    'micro-b-2key',
  ];

  Map<String, dynamic>? findAsset(List<dynamic> assets) {
    final keyword = _assetKeyword;

    for (final a in assets) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      if (!name.endsWith('.bin')) continue;
      if (keyword != null && name.contains(keyword)) {
        return a as Map<String, dynamic>;
      }
    }

    if (this == HardwareVariant.microUsb4Key) {
      for (final a in assets) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        if (!name.endsWith('.bin')) continue;
        final hasAnyKnownKeyword = _allKeywords.any((k) => name.contains(k));
        if (!hasAnyKnownKeyword) {
          return a as Map<String, dynamic>;
        }
      }
    }

    return null;
  }

  static HardwareVariant? fromName(String? name) {
    if (name == null) return null;
    for (final v in HardwareVariant.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
