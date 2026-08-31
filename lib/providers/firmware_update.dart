import 'dart:async';
import 'dart:io';
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
  static const int cmdIapInfo = 0x84;

  // ============================================================
  // OTA MEMORY ADDRESSES
  // ============================================================

  static const int imageAStartAddr = 0x00001000;
  static const int imageBStartAddr = 0x00037000;

  static const int flashEraseBlockSize = 4096;

  static const Duration eraseDelay = Duration(milliseconds: 600);
  static const Duration endDelay = Duration(milliseconds: 500);

  static const int _pacingEveryNChunks = 8;
  static const Duration _pacingDelay = Duration(milliseconds: 4);

  static const Duration _writeTimeout = Duration(seconds: 4);

  static const int verifyEveryNChunks = 0;

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
    // Su Linux/BlueZ, il badge espone il servizio 0000fee0 due volte
    // (due istanze a handle diversi); una delle due non contiene FEE2,
    // e universal_ble risolve per UUID (non per handle/istanza), quindi
    // la lettura di FEE2 può fallire con characteristicNotFound anche
    // se il device la espone davvero in un'altra istanza del servizio.
    // Su Linux bypassiamo FEE2 e usiamo CMD_IAP_INFO su FEE1, che è
    // raggiungibile senza ambiguità.
    if (Platform.isLinux) {
      return _queryActiveSlotViaInfo(deviceId);
    }

    try {
      final services = await UniversalBle.discoverServices(deviceId);

      final hasSlotChar = services.any((s) =>
          BleUuidParser.compareStrings(s.uuid, otaServiceUuid) &&
          s.characteristics.any((c) => BleUuidParser.compareStrings(
              c.uuid, slotStatusCharacteristicUuid)));

      if (!hasSlotChar) {
        logger.w('FEE2 non trovata dopo discovery esplicita: fallback a SlotA');
        return ActiveSlot.slotA;
      }

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
      logger.w('FEE2 non presente: fallback a SlotA — errore: $e');
      return ActiveSlot.slotA;
    }
  }

  /// Interroga lo slot attivo tramite CMD_IAP_INFO (0x84) su FEE1.
  /// Il firmware risponde con un pacchetto staged (letto subito dopo la
  /// write) il cui primo byte è THIS_IMAGE_FLAG (0x01 = SlotA, 0x02 = SlotB).
  Future<ActiveSlot> _queryActiveSlotViaInfo(String deviceId) async {
    try {
      logger.i('Reading active slot via CMD_IAP_INFO (FEE1)...');

      final packet = Uint8List(2);
      packet[0] = cmdIapInfo;
      packet[1] = 0x00;

      await UniversalBle.write(
        deviceId,
        otaServiceUuid,
        otaCharacteristicUuid,
        packet,
        withoutResponse: false,
      ).timeout(const Duration(seconds: 3));

      // Piccola attesa per dare tempo al firmware di preparare la risposta
      // staged prima di leggerla.
      await Future.delayed(const Duration(milliseconds: 100));

      final data = await UniversalBle.read(
        deviceId,
        otaServiceUuid,
        otaCharacteristicUuid,
        timeout: const Duration(seconds: 3),
      );

      if (data.isNotEmpty) {
        if (data[0] == 0x01) return ActiveSlot.slotA;
        if (data[0] == 0x02) return ActiveSlot.slotB;
      }

      logger.w('CMD_IAP_INFO: risposta inattesa, fallback a SlotA. data=$data');
      return ActiveSlot.slotA;
    } catch (e) {
      logger.w('CMD_IAP_INFO fallito: fallback a SlotA — errore: $e');
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
    logger.i(
      'OTA: ERASE slot target a 0x${targetStartAddr.toRadixString(16)} '
      '(${binaryLength} byte, blocco erase=$flashEraseBlockSize byte)',
    );

    const int relativeOffset = 0;
    final int addrCalc = relativeOffset ~/ 16;
    final int addrLsb = addrCalc & 0xFF;
    final int addrMsb = (addrCalc >> 8) & 0xFF;

    final int numBlocks = (binaryLength / flashEraseBlockSize).ceil();
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
    ).timeout(_writeTimeout);

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
    required int maxChunkSize,
    Function(double progress)? onProgress,
  }) async {
    final int total = firmware.length;
    final int chunkSize = maxChunkSize;

    logger.i(
      'OTA: Invio $total byte (Chunk: $chunkSize B)...',
    );

    int lastReportedPct = -1;

    for (int offset = 0; offset < total; offset += chunkSize) {
      final int end = (offset + chunkSize < total) ? offset + chunkSize : total;
      final int currentSize = end - offset;
      final Uint8List chunk = firmware.sublist(offset, end);

      final int addrCalc = offset ~/ 16;
      final int addrLsb = addrCalc & 0xFF;
      final int addrMsb = (addrCalc >> 8) & 0xFF;

      final packet = Uint8List(4 + currentSize);
      packet[0] = cmdIapProm;
      packet[1] = currentSize;
      packet[2] = addrLsb;
      packet[3] = addrMsb;
      packet.setRange(4, 4 + currentSize, chunk);

      bool sent = false;
      int attempt = 0;
      while (!sent) {
        attempt++;
        try {
          await UniversalBle.write(
            deviceId,
            otaServiceUuid,
            otaCharacteristicUuid,
            packet,
            withoutResponse: false,
            queueId: deviceId,
          ).timeout(_writeTimeout);
          sent = true;
        } on TimeoutException {
          logger.e('OTA: timeout offset=$offset (tentativo $attempt)');
          UniversalBle.clearQueue(deviceId);
          await Future.delayed(const Duration(milliseconds: 200));

          if (attempt >= 2) {
            rethrow;
          }
        }
      }

      final int written = offset + currentSize;
      final double progress = (written / total).clamp(0.0, 1.0);

      final int pct = (progress * 100).floor();
      if (pct != lastReportedPct) {
        lastReportedPct = pct;
        onProgress?.call(progress);
      }

      await Future.delayed(const Duration(milliseconds: 5));
    }

    onProgress?.call(1.0);
    logger.i('OTA: Scrittura terminata.');
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
      ).timeout(_writeTimeout);
    } catch (e) {
      logger.w('Disconnessione durante il reboot del badge: $e');
    }

    await Future.delayed(endDelay);
  }

  // ============================================================
  // MAIN OTA
  // ============================================================

  bool _updateInProgress = false;

  Future<void> executeFirmwareUpdate({
    required String deviceId,
    required List<dynamic> releaseAssets,
    required String hardwareVariant,
    Function(double progress)? onProgress,
  }) async {
    if (_updateInProgress) {
      logger.w('OTA: update già in corso, richiesta ignorata');
      return;
    }
    _updateInProgress = true;

    try {
      UniversalBle.timeout = _writeTimeout;
      UniversalBle.queueType = QueueType.perDevice;

      try {
        await UniversalBle.requestConnectionPriority(
          deviceId,
          BleConnectionPriority.highPerformance,
        );
      } catch (_) {}

      int negotiatedMtu = 247;
      if (!Platform.isLinux) {
        try {
          negotiatedMtu = await UniversalBle.requestMtu(deviceId, 512);
          logger.i('MTU Negoziato: $negotiatedMtu');
        } catch (e) {
          logger.w('Fallback MTU: $e');
        }
      }

      final int firmwareIapMaxBuffer = 240;
      int maxDataPayload = (negotiatedMtu - 7).clamp(16, firmwareIapMaxBuffer);
      maxDataPayload = maxDataPayload & ~3;

      final activeSlot = await queryActiveSlot(deviceId);
      final targetSlot = targetSlotFor(activeSlot);
      final int targetAddr = targetSlotAddress(targetSlot);

      final firmware = await downloadFirmwareBinary(activeSlot: activeSlot);

      await _erase(deviceId, targetAddr, firmware.length);

      await _program(
        deviceId,
        firmware,
        targetSlot: targetSlot,
        maxChunkSize: maxDataPayload,
        onProgress: onProgress,
      );

      await _end(deviceId, targetSlot);
    } finally {
      _updateInProgress = false;
    }
  }
}