import 'package:flutter/material.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final String serviceUuid = "0000fee0-0000-1000-8000-00805f9b34fb";
final String characteristicUuid = "0000fee1-0000-1000-8000-00805f9b34fb";

/// Advertised-name prefixes that identify a badge.
///
/// The OEM firmware advertises as "LSLED" but does **not** put 0xFEE0 in its
/// advertisement packet - the service is only visible after connecting. So a
/// scan filtered purely on [serviceUuid] never reports it, and the app reports
/// "Device not found" for a badge that is sitting right there.
///
/// Kept deliberately narrow. The stock vendor app matches any name *containing*
/// "LS", but a false positive here is not free: [ScanState] stops scanning on
/// the first match and hands the device to the connect step, so latching onto
/// an unrelated device fails the whole transfer rather than skipping past it.
/// "LSLED" is the name observed on OEM hardware; because matching is by prefix,
/// suffixed variants such as "LSLED-1234" are still covered. Additional OEM
/// names can be appended here as they are reported.
///
/// Matching is case-sensitive by necessity, not by preference: these prefixes
/// are also handed to `universal_ble` as a `ScanFilter.withNamePrefix`, and both
/// its Dart and Kotlin matchers use a case-sensitive `startsWith`. A device
/// whose name differed only in case would be dropped by that filter before ever
/// reaching this app's callback, so folding case here would suggest a tolerance
/// the scan pipeline does not actually have.
const List<String> badgeNamePrefixes = <String>[
  'LSLED', // OEM firmware
  'LED Badge Magic', // open firmware default name
];

/// Whether [deviceName] identifies a badge by its advertised name.
///
/// Centralised so the scan filter and the scan callback cannot drift apart:
/// both must agree on trimming and case, or a device the filter admits gets
/// rejected by the callback (or vice versa).
bool matchesBadgeName(String? deviceName) {
  final name = (deviceName ?? '').trim();
  if (name.isEmpty) return false;
  return badgeNamePrefixes.any(name.startsWith);
}
