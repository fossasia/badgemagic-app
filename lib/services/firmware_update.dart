import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

import '../badgemagic_module/utils/byte_array_utils.dart';
import '../badgemagic_module/utils/toast_utils.dart';
import '../globals/globals.dart';
import '../providers/BadgeScanProvider.dart';
import 'localization_service.dart';

enum ActiveSlot {
  slotA,
  slotB,
  unknown,
  legacyFirmware,
}

class FirmwareUpdateService {
  static const String _apiLatestUrl =
      'https://api.github.com/repos/fossasia/badgemagic-firmware/releases/latest';

  static const String _prefKeySkipVersion = 'skip_firmware_version_';

  // ============================================================
  // BLE UUID
  // ============================================================

  static const String otaServiceUuid = '0000fee0-0000-1000-8000-00805f9b34fb';

  static const String otaCharacteristicUuid =
      '0000fee1-0000-1000-8000-00805f9b34fb';

  static const String slotStatusCharacteristicUuid =
      '0000fee2-0000-1000-8000-00805f9b34fb';

  // ============================================================
  // OTA COMMANDS
  // ============================================================

  static const int cmdIapErase = 0x81;
  static const int cmdIapProm = 0x82;
  static const int cmdIapEnd = 0x83;

  // ============================================================
  // OTA SETTINGS
  // ============================================================

  static const int firmwareChunkSize = 64;

  static const Duration eraseDelay = Duration(milliseconds: 800);

  static const Duration promDelay = Duration(milliseconds: 15);

  static const Duration endDelay = Duration(milliseconds: 500);

  // ============================================================
  // UPDATE CHECK
  // ============================================================

  /*Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_apiLatestUrl),
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final String version = data['tag_name'] ?? '';

        final String rawDate = data['published_at'] ?? '';

        final List<dynamic> assets = data['assets'] ?? [];

        if (version.isEmpty) {
          return null;
        }

        String formattedDate = rawDate;

        if (rawDate.isNotEmpty) {
          try {
            final parsedDate = DateTime.parse(rawDate);

            formattedDate = DateFormat.yMMMd().format(parsedDate);
          } catch (_) {}
        }

        return {
          'version': version,
          'date': formattedDate,
          'assets': assets,
        };
      }

      final l10n = GetIt.instance.get<LocalizationService>().l10n;

      ToastUtils().showToast(
        l10n.checkFirmwareFailed,
      );
    } catch (e) {
      logger.e(
        'Firmware update check failed: $e',
      );
    }

    return null;
  }*/

  Future<Map<String, dynamic>?> checkForUpdates() async {
    return {
      'version': 1,
      'date': 15 - 05 - 2025,
      'assets': <dynamic>[],
    };
  }

  Future<void> skipVersionPermanently(
    String version,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      '$_prefKeySkipVersion$version',
      true,
    );
  }

  // ============================================================
  // SLOT
  // ============================================================

  Future<ActiveSlot> queryActiveSlot(
    String deviceId,
  ) async {
    try {
      logger.i(
        'Reading active slot from FEE2...',
      );

      final data = await UniversalBle.read(
        deviceId,
        otaServiceUuid,
        slotStatusCharacteristicUuid,
        timeout: const Duration(seconds: 5),
      );

      if (data.isEmpty) {
        logger.w(
          'FEE2 returned empty response',
        );

        return ActiveSlot.unknown;
      }

      final value = data[0];

      logger.i(
        'FEE2 returned 0x${value.toRadixString(16).padLeft(2, '0')}',
      );

      switch (value) {
        case 0x01:
          return ActiveSlot.slotA;

        case 0x02:
          return ActiveSlot.slotB;

        default:
          logger.w(
            'Invalid FEE2 slot value: '
            '0x${value.toRadixString(16)}',
          );

          return ActiveSlot.unknown;
      }
    } catch (e) {
      logger.w(
        'FEE2 read failed. '
        'Possible legacy firmware: $e',
      );

      return ActiveSlot.legacyFirmware;
    }
  }

  ActiveSlot targetSlotFor(
    ActiveSlot activeSlot,
  ) {
    switch (activeSlot) {
      case ActiveSlot.slotA:
        return ActiveSlot.slotB;

      case ActiveSlot.slotB:
        return ActiveSlot.slotA;

      default:
        throw Exception(
          'Cannot determine OTA target slot '
          'from $activeSlot',
        );
    }
  }

  String slotName(
    ActiveSlot slot,
  ) {
    switch (slot) {
      case ActiveSlot.slotA:
        return 'SlotA';

      case ActiveSlot.slotB:
        return 'SlotB';

      default:
        return 'Unknown';
    }
  }

  // ============================================================
  // DOWNLOAD FIRMWARE
  // ============================================================

  /*Future<Uint8List> downloadFirmwareBinary({
    required List<dynamic> assets,
    required String hardwareVariant,
    required ActiveSlot activeSlot,
  }) async {
    final targetSlot = targetSlotFor(activeSlot);

    final expectedFileName = 'badgemagic_${hardwareVariant}_'
        '${slotName(targetSlot)}.bin';

    logger.i(
      'Expected OTA binary: $expectedFileName',
    );

    dynamic asset;

    try {
      asset = assets.firstWhere(
        (a) {
          final name = (a['name'] as String).toLowerCase();

          return name == expectedFileName.toLowerCase();
        },
      );
    } catch (_) {
      throw Exception(
        'Firmware asset not found: '
        '$expectedFileName',
      );
    }

    final String downloadUrl = asset['browser_download_url'];

    logger.i(
      'Downloading firmware: $downloadUrl',
    );

    final response = await http.get(
      Uri.parse(downloadUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Firmware download failed: '
        '${response.statusCode}',
      );
    }

    final firmware = Uint8List.fromList(
      response.bodyBytes,
    );

    if (firmware.isEmpty) {
      throw Exception(
        'Downloaded firmware is empty',
      );
    }

    logger.i(
      'Firmware downloaded: '
      '${firmware.length} bytes',
    );

    return firmware;
  }*/

  /*
Future<Uint8List> downloadFirmwareBinary({
  required List<dynamic> assets,
  required String hardwareVariant,
  required ActiveSlot activeSlot,
}) async {
  String targetSlot;

  if (activeSlot == ActiveSlot.slotA) {
    targetSlot = "SlotB";
  } else if (activeSlot == ActiveSlot.slotB) {
    targetSlot = "SlotA";
  } else {
    throw Exception(
      'Impossibile determinare lo slot di destinazione '
      '(activeSlot=$activeSlot).',
    );
  }

  final expectedFileName =
      'badgemagic_${hardwareVariant}_$targetSlot.bin';

  final asset = assets.firstWhere(
    (a) =>
        (a['name'] as String).toLowerCase() ==
        expectedFileName.toLowerCase(),
    orElse: () =>
        throw Exception('Binary asset not found: $expectedFileName'),
  );

  final String downloadUrl =
      asset['browser_download_url'];

  final response =
      await http.get(Uri.parse(downloadUrl));

  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception(
      'Failed to download firmware binary from $downloadUrl',
    );
  }
}
*/

  /// TEMPORARY:
  /// from local filesystem and Slot B
  Future<Uint8List> downloadFirmwareBinary({
    required ActiveSlot activeSlot,
  }) async {
    if (activeSlot != ActiveSlot.slotA) {
      throw Exception(
        'Firmware locale disponibile solo per '
        'Slot B. '
        'Slot attivo rilevato: $activeSlot',
      );
    }

    const firmwarePath = '/home/riccardo/Scaricati/badgemagic-firmware/'
        'usb-c-4key/slotB/'
        'badgemagic-ch582-slotB.bin';

    final file = File(firmwarePath);

    if (!await file.exists()) {
      throw Exception(
        'Firmware locale non trovato:\n'
        '$firmwarePath',
      );
    }

    final firmware = await file.readAsBytes();

    if (firmware.isEmpty) {
      throw Exception(
        'Il firmware locale è vuoto:\n'
        '$firmwarePath',
      );
    }

    logger.i(
      'Firmware locale caricato: '
      '$firmwarePath',
    );

    logger.i(
      'Dimensione firmware: '
      '${firmware.length} byte',
    );

    return firmware;
  }
  // ============================================================
  // BLE WRITE HELPER
  // ============================================================

  Future<void> _writeOta(
    String deviceId,
    Uint8List data, {
    required bool withoutResponse,
    required String description,
  }) async {
    logger.d(
      '$description: ${data.length} bytes '
      '(withoutResponse=$withoutResponse)',
    );

    final state = await UniversalBle.getConnectionState(
      deviceId,
      timeout: const Duration(seconds: 5),
    );

    logger.d('BLE connection state: $state');

    await UniversalBle.write(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
      data,
      withoutResponse: withoutResponse,
      timeout: const Duration(seconds: 10),
    );
  }

  // ============================================================
  // ERASE
  // ============================================================

  Future<void> _erase(
    String deviceId,
  ) async {
    logger.i(
      'OTA: ERASE',
    );

    final packet = Uint8List.fromList([
      cmdIapErase,
      ...List<int>.filled(15, 0),
    ]);

    await _writeOta(
      deviceId,
      packet,
      withoutResponse: false,
      description: 'CMD_IAP_ERASE',
    );

    await Future.delayed(
      eraseDelay,
    );

    logger.i(
      'OTA: ERASE completed',
    );
  }

  // ============================================================
  // PROM
  // ============================================================

  Future<void> _program(
    String deviceId,
    Uint8List firmware, {
    Function(double progress)? onProgress,
  }) async {
    final total = firmware.length;

    logger.i(
      'OTA: programming '
      '$total bytes',
    );

    logger.i(
      'Firmware chunk: '
      '$firmwareChunkSize bytes',
    );

    logger.i(
      'BLE packet: '
      '${firmwareChunkSize + 1} bytes',
    );

    for (int offset = 0; offset < total; offset += firmwareChunkSize) {
      final int end = (offset + firmwareChunkSize < total)
          ? offset + firmwareChunkSize
          : total;

      final chunk = firmware.sublist(
        offset,
        end,
      );

      final packet = Uint8List.fromList([
        cmdIapProm,
        ...chunk,
      ]);

      await _writeOta(
        deviceId,
        packet,
        withoutResponse: false,
        description: 'CMD_IAP_PROM '
            '@ 0x${offset.toRadixString(16).padLeft(6, '0')}',
      );

      final written = offset + chunk.length;

      final progress = written / total;

      onProgress?.call(
        progress.clamp(0.0, 1.0),
      );

      if (offset % (firmwareChunkSize * 32) == 0 || written == total) {
        logger.i(
          'OTA progress: '
          '${(progress * 100).toStringAsFixed(1)}% '
          '($written/$total)',
        );
      }

      await Future.delayed(
        promDelay,
      );
    }

    logger.i(
      'OTA: programming completed',
    );
  }

  // ============================================================
  // END
  // ============================================================

  Future<void> _end(
    String deviceId,
  ) async {
    logger.i(
      'OTA: END',
    );

    final packet = Uint8List.fromList([
      cmdIapEnd,
      ...List<int>.filled(15, 0),
    ]);

    try {
      await _writeOta(
        deviceId,
        packet,
        withoutResponse: false,
        description: 'CMD_IAP_END',
      );
    } catch (e) {
      logger.w(
        'Connection lost during OTA reboot: $e',
      );
    }

    await Future.delayed(
      endDelay,
    );
  }

  // ============================================================
  // MAIN OTA
  // ============================================================

  Future<void> executeFirmwareUpdate({
    required String deviceId,
    required List<dynamic> releaseAssets,
    required String hardwareVariant,
    Function(double progress)? onProgress,
    Future<bool> Function()? onLegacyFirmwareDetected,
  }) async {
    logger.i(
      '====================================',
    );

    logger.i(
      'START DIRECT-XIP OTA',
    );

    logger.i(
      '====================================',
    );

    // ----------------------------------------------------------
    // 1. SLOT DETECTION
    // ----------------------------------------------------------

    final activeSlot = await queryActiveSlot(
      deviceId,
    );

    if (activeSlot == ActiveSlot.legacyFirmware) {
      final continueLegacy =
          onLegacyFirmwareDetected != null && await onLegacyFirmwareDetected();

      if (!continueLegacy) {
        throw Exception(
          'Legacy firmware detected. '
          'FEE2 is unavailable.',
        );
      }

      throw Exception(
        'Legacy OTA flow must be handled separately.',
      );
    }

    if (activeSlot == ActiveSlot.unknown) {
      throw Exception(
        'Invalid active slot returned by FEE2.',
      );
    }

    // ----------------------------------------------------------
    // 2. TARGET SLOT
    // ----------------------------------------------------------

    final targetSlot = targetSlotFor(activeSlot);

    logger.i(
      'Active slot: '
      '${slotName(activeSlot)}',
    );

    logger.i(
      'Target slot: '
      '${slotName(targetSlot)}',
    );

    // ----------------------------------------------------------
    // 3. DOWNLOAD CORRECT BINARY
    // ----------------------------------------------------------

    final firmware = await downloadFirmwareBinary(
      //assets: releaseAssets,
      //hardwareVariant: hardwareVariant,
      activeSlot: activeSlot,
    );

    logger.i(
      'Firmware size: '
      '${firmware.length} bytes',
    );

    try {
      final mtu = await UniversalBle.requestMtu(
        deviceId,
        247,
        timeout: const Duration(seconds: 5),
      );

      logger.i(
        'Negotiated/requested MTU: $mtu',
      );
    } catch (e) {
      logger.w(
        'MTU request failed/unsupported: $e',
      );
    }

    // ----------------------------------------------------------
    // 5. ANDROID CONNECTION PRIORITY
    // ----------------------------------------------------------

    try {
      await UniversalBle.requestConnectionPriority(
        deviceId,
        BleConnectionPriority.highPerformance,
        timeout: const Duration(seconds: 5),
      );

      logger.i(
        'BLE high performance mode enabled',
      );
    } catch (e) {
      // iOS/Linux/Windows/Web possono non supportarlo.
      logger.d(
        'High performance BLE not available: $e',
      );
    }

    // ----------------------------------------------------------
    // 6. FINAL SAFETY LOG
    // ----------------------------------------------------------

    logger.i(
      '------------------------------------',
    );

    logger.i(
      'OTA READY',
    );

    logger.i(
      'Active : ${slotName(activeSlot)}',
    );

    logger.i(
      'Target : ${slotName(targetSlot)}',
    );

    logger.i(
      'Size   : ${firmware.length} bytes',
    );

    logger.i(
      '------------------------------------',
    );

    // ----------------------------------------------------------
    // 7. ERASE
    // ----------------------------------------------------------

    await _erase(
      deviceId,
    );

    // ----------------------------------------------------------
    // 8. PROGRAM
    // ----------------------------------------------------------

    await _program(
      deviceId,
      firmware,
      onProgress: onProgress,
    );

    // ----------------------------------------------------------
    // 9. END / REBOOT
    // ----------------------------------------------------------

    await _end(
      deviceId,
    );

    logger.i(
      '====================================',
    );

    logger.i(
      'OTA COMPLETE',
    );

    logger.i(
      'Expected active slot after reboot: '
      '${slotName(targetSlot)}',
    );

    logger.i(
      '====================================',
    );
  }
}
