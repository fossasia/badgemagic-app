import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

import '../others/byte_array_utils.dart';

enum ActiveSlot {
  slotA,
  slotB,
  unknown,
  legacyFirmware,
}

class FirmwareUpdateService {
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

  static const Duration eraseDelay = Duration(milliseconds: 600);
  static const Duration endDelay = Duration(milliseconds: 500);

  // ============================================================
  // UPDATE CHECK
  // ============================================================

  Future<Map<String, dynamic>?> checkForUpdates() async {
    return {
      'version': '1.0.0',
      'date': '15 May 2026',
      'assets': <dynamic>[],
    };
  }

  Future<void> skipVersionPermanently(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeySkipVersion$version', true);
  }

  // ============================================================
  // SLOT
  // ============================================================

  Future<ActiveSlot> queryActiveSlot(String deviceId) async {
    try {
      logger.i('Reading active slot from FEE2...');
      final data = await UniversalBle.read(
        deviceId,
        otaServiceUuid,
        slotStatusCharacteristicUuid,
        timeout: const Duration(seconds: 3),
      );

      if (data.isNotEmpty) {
        if (data[0] == 0x01) return ActiveSlot.slotA;
        if (data[0] == 0x02) return ActiveSlot.slotB;
      }
      return ActiveSlot.slotA;
    } catch (e) {
      logger.w('FEE2 non presente: fallback a SlotA');
      return ActiveSlot.slotA;
    }
  }

  ActiveSlot targetSlotFor(ActiveSlot activeSlot) =>
      (activeSlot == ActiveSlot.slotA) ? ActiveSlot.slotB : ActiveSlot.slotA;

  String slotName(ActiveSlot slot) =>
      slot == ActiveSlot.slotA ? 'SlotA' : 'SlotB';

  // ============================================================
  // DOWNLOAD FIRMWARE
  // ============================================================

  Future<Uint8List> downloadFirmwareBinary({
    required ActiveSlot activeSlot,
  }) async {
    if (activeSlot != ActiveSlot.slotA) {
      throw Exception(
        'Firmware locale disponibile solo per Slot B. '
        'Slot attivo rilevato: $activeSlot',
      );
    }

    const String assetPath =
        'assets/usb-c-4key/slotB/badgemagic-ch582-slotB.bin';

    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List firmware = byteData.buffer.asUint8List();

      if (firmware.isEmpty) {
        throw Exception('Il file binario dell\'asset è vuoto (0 byte).');
      }

      logger.i('Firmware asset caricato: ${firmware.length} byte');
      return firmware;
    } catch (e) {
      throw Exception('Errore caricamento asset firmware: $e');
    }
  }

  // ============================================================
  // ERASE
  // ============================================================

  Future<void> _erase(String deviceId) async {
    logger.i('OTA: ERASE');
    final packet = Uint8List.fromList([
      cmdIapErase,
      ...List<int>.filled(15, 0),
    ]);

    await UniversalBle.write(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
      packet,
      withoutResponse: false,
    );

    await Future.delayed(eraseDelay);
    logger.i('OTA: ERASE completed');
  }

  // ============================================================
  // PROM (Con aggiornamento notifica e offset Slot B)
  // ============================================================

  Future<void> _program(
    String deviceId,
    Uint8List firmware, {
    required ActiveSlot targetSlot,
    required int maxChunkSize,
    Function(double progress)? onProgress,
  }) async {
    final int total = firmware.length;
    final int chunkSize = maxChunkSize;

    final int startAddr =
        (targetSlot == ActiveSlot.slotB) ? 0x00010000 : 0x00000000;

    logger.i(
        'OTA: Invio $total byte (Chunk: $chunkSize, Base: 0x${startAddr.toRadixString(16)})...');

    for (int offset = 0; offset < total; offset += chunkSize) {
      final int end = (offset + chunkSize < total) ? offset + chunkSize : total;
      final int currentSize = end - offset;
      final Uint8List chunk = firmware.sublist(offset, end);

      final int absoluteAddr = startAddr + offset;
      final int addrCalc = absoluteAddr ~/ 16;
      final int addrLsb = addrCalc & 0xFF;
      final int addrMsb = (addrCalc >> 8) & 0xFF;

      final packet = Uint8List(4 + currentSize);
      packet[0] = cmdIapProm; // 0x82
      packet[1] = currentSize;
      packet[2] = addrLsb;
      packet[3] = addrMsb;
      packet.setRange(4, 4 + currentSize, chunk);

      await UniversalBle.write(
        deviceId,
        otaServiceUuid,
        otaCharacteristicUuid,
        packet,
        withoutResponse: false,
      );

      final int written = offset + currentSize;
      final double progress = (written / total).clamp(0.0, 1.0);

      onProgress?.call(progress);
    }

    logger.i('OTA: Scrittura firmware terminata con successo.');
  }

  // ============================================================
  // END
  // ============================================================

  Future<void> _end(String deviceId) async {
    logger.i('OTA: END');
    final packet = Uint8List.fromList([
      cmdIapEnd,
      ...List<int>.filled(15, 0),
    ]);

    try {
      await UniversalBle.write(
        deviceId,
        otaServiceUuid,
        otaCharacteristicUuid,
        packet,
        withoutResponse: false,
      );
    } catch (e) {
      logger.w('Disconnessione durante il reboot del badge: $e');
    }

    await Future.delayed(endDelay);
  }

  // ============================================================
  // MAIN OTA
  // ============================================================

  Future<void> executeFirmwareUpdate({
    required String deviceId,
    required List<dynamic> releaseAssets,
    required String hardwareVariant,
    Function(double progress)? onProgress,
  }) async {
    int negotiatedMtu = 23;
    try {
      negotiatedMtu = await UniversalBle.requestMtu(
        deviceId,
        247,
        timeout: const Duration(seconds: 4),
      );
      logger.i('Negotiated MTU: $negotiatedMtu');
    } catch (e) {
      logger.w('Richiesta MTU non supportata: $e');
    }

    final int rawPayload = (negotiatedMtu > 23) ? (negotiatedMtu - 7) : 16;
    final int safeChunkSize = ((rawPayload ~/ 16) * 16).clamp(16, 240);

    final activeSlot = await queryActiveSlot(deviceId);
    final targetSlot = targetSlotFor(activeSlot);
    logger.i(
        'Active: ${slotName(activeSlot)} -> Target: ${slotName(targetSlot)}');

    final firmware = await downloadFirmwareBinary(activeSlot: activeSlot);

    await _erase(deviceId);

    await _program(
      deviceId,
      firmware,
      targetSlot: targetSlot,
      maxChunkSize: safeChunkSize,
      onProgress: onProgress,
    );

    await _end(deviceId);
  }
}
