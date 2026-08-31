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

  // Granularità minima di erase del Code Flash sui CH58x/CH582.
  // ATTENZIONE: verifica questo valore contro la costante reale usata dal
  // firmware (FLASH_BLOCK_SIZE / EEPROM_BLOCK_SIZE nel tuo ota.h/config.h).
  // Sulla famiglia CH58x l'erase del code flash è tipicamente allineato a
  // blocchi da 4096 byte (non 512): se il firmware usa un valore diverso,
  // aggiorna SOLO questa costante.
  static const int flashEraseBlockSize = 4096;

  static const Duration eraseDelay = Duration(milliseconds: 600);
  static const Duration endDelay = Duration(milliseconds: 500);

  // Pacing tra un chunk di programmazione e il successivo. Con
  // withoutResponse=true non serve attendere un ack per ogni pacchetto: si
  // fa una pausa breve ogni [_pacingEveryNChunks] pacchetti per non saturare
  // lo stack BLE / il buffer di trasmissione del controller.
  static const int _pacingEveryNChunks = 8;
  static const Duration _pacingDelay = Duration(milliseconds: 4);

  static const Duration _writeTimeout = Duration(seconds: 4);

  // Se > 0, ogni N chunk viene inviato anche un CMD_IAP_VERIFY sul blocco
  // appena scritto (il firmware supporta già questo comando). Disattivato
  // di default per non rallentare l'update; abilitalo se vuoi più
  // robustezza a scapito della velocità.
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
  //
  // IMPORTANTE: il firmware, alla ricezione di CMD_IAP_ERASE, calcola
  //   OpAdd = (addr_ricevuto * 16) + OTA_TARGET_START_ADD
  // quindi l'indirizzo che inviamo via BLE deve essere un OFFSET
  // RELATIVO all'inizio dello slot target (0 per l'inizio immagine),
  // NON l'indirizzo assoluto: altrimenti il firmware somma due volte la
  // base e il suo controllo di bound rifiuta il comando (o, peggio,
  // scrive fuori dallo slot corretto).

  Future<void> _erase(
    String deviceId,
    int targetStartAddr,
    int binaryLength,
  ) async {
    logger.i(
      'OTA: ERASE slot target a 0x${targetStartAddr.toRadixString(16)} '
      '(${binaryLength} byte, blocco erase=$flashEraseBlockSize byte)',
    );

    const int relativeOffset = 0; // si cancella sempre dall'inizio dello slot
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
  //
  // Stesso discorso dell'erase: l'indirizzo inviato per ogni chunk deve
  // essere l'offset RELATIVO all'inizio dello slot target (offset ~/ 16),
  // non (startAddr + offset) ~/ 16. Il firmware aggiunge già
  // OTA_TARGET_START_ADD internamente.

  Future<void> _program(
    String deviceId,
    Uint8List firmware, {
    required ActiveSlot targetSlot,
    Function(double progress)? onProgress,
  }) async {
    final int total = firmware.length;
    const int chunkSize = 16;
    final int startAddr = targetSlotAddress(targetSlot); // solo per log

    logger.i(
      'OTA: Invio $total byte (Chunk: $chunkSize, Base target: 0x${startAddr.toRadixString(16)})...',
    );

    int chunkIndex = 0;
    int lastReportedPct = -1;

    for (int offset = 0; offset < total; offset += chunkSize) {
      final int end = (offset + chunkSize < total) ? offset + chunkSize : total;
      final int currentSize = end - offset;
      final Uint8List chunk = firmware.sublist(offset, end);

      // Offset relativo allo slot target: NON sommare startAddr qui.
      final int addrCalc = offset ~/ 16;
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
        // Il characteristic FEE1 espone GATT_PROP_WRITE_NO_RSP: per i
        // pacchetti di programmazione possiamo evitare di attendere un
        // ack per ognuno, guadagnando parecchio in velocità.
        withoutResponse: false,
      ).timeout(_writeTimeout);

      chunkIndex++;

      // Verifica opzionale (disattivata di default, vedi verifyEveryNChunks)
      if (verifyEveryNChunks > 0 && chunkIndex % verifyEveryNChunks == 0) {
        await _verifyChunk(
          deviceId,
          relativeOffset: offset,
          data: chunk,
        );
      }

      final int written = offset + currentSize;
      final double progress = (written / total).clamp(0.0, 1.0);

      // Throttle: notifica la UI solo quando la percentuale intera cambia,
      // invece che ad ogni singolo pacchetto da 16 byte.
      final int pct = (progress * 100).floor();
      if (pct != lastReportedPct) {
        lastReportedPct = pct;
        onProgress?.call(progress);
      }

      if (chunkIndex % _pacingEveryNChunks == 0) {
        await Future.delayed(_pacingDelay);
      }
    }

    // Garantisce che l'ultimo progress (100%) venga sempre notificato.
    onProgress?.call(1.0);

    logger.i('OTA: Scrittura firmware terminata con successo.');
  }

  /// Invia CMD_IAP_VERIFY per il blocco appena scritto. Usa lo stesso
  /// schema di indirizzamento relativo di _program.
  Future<void> _verifyChunk(
    String deviceId, {
    required int relativeOffset,
    required Uint8List data,
  }) async {
    final int addrCalc = relativeOffset ~/ 16;
    final int addrLsb = addrCalc & 0xFF;
    final int addrMsb = (addrCalc >> 8) & 0xFF;

    final packet = Uint8List(20);
    packet[0] = cmdIapVerify;
    packet[1] = data.length;
    packet[2] = addrLsb;
    packet[3] = addrMsb;
    packet.setRange(4, 4 + data.length, data);

    await UniversalBle.write(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
      packet,
      withoutResponse: false,
    ).timeout(_writeTimeout);
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
