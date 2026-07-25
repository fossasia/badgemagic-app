import 'package:flutter/material.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final String serviceUuid = "0000fee0-0000-1000-8000-00805f9b34fb";
final String characteristicUuid = "0000fee1-0000-1000-8000-00805f9b34fb";

/// Advertised-name prefixes that identify a badge.
///
/// The OEM firmware advertises as "LSLED" but does **not** put 0xFEE0 in its
/// advertisement packet - the service is only visible after connecting. So a
/// scan filtered purely on [serviceUuid] never reports it, and the app reports
/// "Device not found" for a badge that is sitting right there. The stock vendor
/// app scans unfiltered and matches the name prefix "LS" instead.
///
/// These are matched with a case-sensitive `startsWith`, OR'd against the
/// service-UUID match, so open firmware (which does advertise 0xFEE0, and whose
/// name is user-changeable) keeps working unchanged.
const List<String> badgeNamePrefixes = <String>[
  'LS', // OEM firmware, e.g. "LSLED"
  'LED Badge Magic', // open firmware default name
];
