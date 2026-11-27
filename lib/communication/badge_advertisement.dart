import 'package:badgemagic/others/globals.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

const List<String> defaultBadgeNames = ['lsled', 'vblab'];

// Android drops every field of an advertisement with malformed manufacturer
// data, which some badges send, so badges are matched in-app there instead.
// Web needs the service filter to access the service after connecting.
ScanFilter? get badgeScanFilter =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? null
        : ScanFilter(withServices: [serviceUuid]);

bool isBadgeAdvertisement(BleDevice device, Iterable<String> knownNames) {
  if (device.services.contains(serviceUuid)) return true;
  if (device.services.isNotEmpty) return false;

  // No parsed services: fall back to the name cached by the OS.
  final name = (device.name ?? '').trim().toLowerCase();
  if (name.isEmpty) return false;
  return [...defaultBadgeNames, ...knownNames]
      .any((known) => known.trim().toLowerCase() == name);
}
