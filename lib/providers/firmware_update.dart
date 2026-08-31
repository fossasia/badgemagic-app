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
  // OTA COMMANDS (ota.h)
  // ============================================================

  static const int cmdIapProm = 0x80;
  static const int cmdIapErase = 0x81;
  static const int cmdIapVerify = 0x82;
  static const int cmdIapEnd = 0x83;

  // ============================================================
  // OTA MEMORY ADDRESSES
  // ============================================================

  static const int imageAStartAddr = 0x00001000;
  static const int imageBStartAddr = 0x00037000;

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

  int targetSlotAddress(ActiveSlot targetSlot) =>
      (targetSlot == ActiveSlot.slotB) ? imageBStartAddr : imageAStartAddr;

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

  Future<void> _erase(
      String deviceId,
      int targetStartAddr,
      int binaryLength,
      ) async {
    logger.i('OTA: ERASE all\'indirizzo 0x${targetStartAddr.toRadixString(16)}');

    final int addrCalc = targetStartAddr ~/ 16;
    final int addrLsb = addrCalc & 0xFF;
    final int addrMsb = (addrCalc >> 8) & 0xFF;

    final int numBlocks = (binaryLength / 512).ceil();
    final int blockLsb = numBlocks & 0xFF;
    final int blockMsb = (numBlocks >> 8) & 0xFF;

    final packet = Uint8List(20);
    packet[0] = cmdIapErase;
    packet[1] = 0x04;
    packet[2] = addrLsb;
    packet[3] = addrMsb;
    packet[4] = blockLsb;
    packet[5] = blockMsb;

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
  // PROM
  // ============================================================

  Future<void> _program(
      String deviceId,
      Uint8List firmware, {
        required ActiveSlot targetSlot,
        Function(double progress)? onProgress,
      }) async {
    final int total = firmware.length;
    const int chunkSize = 16;
    final int startAddr = targetSlotAddress(targetSlot);

    logger.i(
      'OTA: Invio $total byte (Chunk: $chunkSize, Base: 0x${startAddr.toRadixString(16)})...',
    );

    for (int offset = 0; offset < total; offset += chunkSize) {
      final int end = (offset + chunkSize < total) ? offset + chunkSize : total;
      final int currentSize = end - offset;
      final Uint8List chunk = firmware.sublist(offset, end);

      final int absoluteAddr = startAddr + offset;
      final int addrCalc = absoluteAddr ~/ 16;
      final int addrLsb = addrCalc & 0xFF;
      final int addrMsb = (addrCalc >> 8) & 0xFF;

      final packet = Uint8List(20);
      packet[0] = cmdIapProm;
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
      await Future.delayed(const Duration(milliseconds: 2));
    }

    logger.i('OTA: Scrittura firmware terminata con successo.');
  }

  // ============================================================
  // END
  // ============================================================

  Future<void> _end(String deviceId, ActiveSlot targetSlot) async {
    logger.i('OTA: END -> Switch a ${slotName(targetSlot)}');

    final packet = Uint8List(20);
    packet[0] = cmdIapEnd;
    packet[1] = 0x02;
    packet[2] = (targetSlot == ActiveSlot.slotB) ? 0x02 : 0x01;
    packet[3] = 0x00;

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
    final activeSlot = await queryActiveSlot(deviceId);
    final targetSlot = targetSlotFor(activeSlot);
    final int targetAddr = targetSlotAddress(targetSlot);

    logger.i(
      'Active: ${slotName(activeSlot)} -> Target: ${slotName(targetSlot)} (0x${targetAddr.toRadixString(16)})',
    );

    final firmware = await downloadFirmwareBinary(activeSlot: activeSlot);

    await _erase(deviceId, targetAddr, firmware.length);

    await _program(
      deviceId,
      firmware,
      targetSlot: targetSlot,
      onProgress: onProgress,
    );

    await _end(deviceId, targetSlot);
  }
}