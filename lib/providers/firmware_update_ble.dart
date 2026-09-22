import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';
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

  static const Duration _writeTimeout = Duration(seconds: 4);

  static const int verifyEveryNChunks = 0;

  // ============================================================
  // SLOT
  // ============================================================

  Future<ActiveSlot> queryActiveSlot(String deviceId) async {
    final ActiveSlot result = Platform.isLinux
        ? await _queryActiveSlotViaInfo(deviceId)
        : await _queryActiveSlotViaChar(deviceId);

    logger.i('OTA: active slot detected -> ${slotName(result)}');
    return result;
  }

  Future<ActiveSlot> _queryActiveSlotViaChar(String deviceId) async {
    try {
      final services = await UniversalBle.discoverServices(deviceId);

      final hasSlotChar = services.any((s) =>
          BleUuidParser.compareStrings(s.uuid, otaServiceUuid) &&
          s.characteristics.any((c) => BleUuidParser.compareStrings(
              c.uuid, slotStatusCharacteristicUuid)));

      if (!hasSlotChar) {
        logger.w('OTA: FEE2 not found after discovery, fallback to SlotA');
        return ActiveSlot.slotA;
      }

      logger.i('OTA: reading active slot from FEE2...');
      final data = await UniversalBle.read(
        deviceId,
        otaServiceUuid,
        slotStatusCharacteristicUuid,
        timeout: const Duration(seconds: 3),
      );
      logger.d('OTA: FEE2 raw response: $data');

      if (data.isNotEmpty) {
        if (data[0] == 0x01) return ActiveSlot.slotA;
        if (data[0] == 0x02) return ActiveSlot.slotB;
      }
      logger.w('OTA: FEE2 returned unexpected data, fallback to SlotA');
      return ActiveSlot.slotA;
    } catch (e) {
      logger.w('OTA: FEE2 not present, fallback to SlotA — error: $e');
      return ActiveSlot.slotA;
    }
  }

  /// Queries active slot via CMD_IAP_INFO (0x84) on FEE1.
  Future<ActiveSlot> _queryActiveSlotViaInfo(String deviceId) async {
    try {
      logger.i('OTA: reading active slot via CMD_IAP_INFO (FEE1)...');

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

      await Future.delayed(const Duration(milliseconds: 100));

      final data = await UniversalBle.read(
        deviceId,
        otaServiceUuid,
        otaCharacteristicUuid,
        timeout: const Duration(seconds: 3),
      );
      logger.d('OTA: CMD_IAP_INFO raw response: $data');

      if (data.isNotEmpty) {
        if (data[0] == 0x01) return ActiveSlot.slotA;
        if (data[0] == 0x02) return ActiveSlot.slotB;
      }

      logger.w(
          'OTA: CMD_IAP_INFO unexpected response, fallback to SlotA. data=$data');
      return ActiveSlot.slotA;
    } catch (e) {
      logger.w('OTA: CMD_IAP_INFO failed, fallback to SlotA — error: $e');
      return ActiveSlot.slotA;
    }
  }

  ActiveSlot targetSlotFor(ActiveSlot activeSlot) =>
      (activeSlot == ActiveSlot.slotA) ? ActiveSlot.slotB : ActiveSlot.slotA;

  String slotName(ActiveSlot slot) {
    switch (slot) {
      case ActiveSlot.slotA:
        return 'SlotA';
      case ActiveSlot.slotB:
        return 'SlotB';
      case ActiveSlot.unknown:
        return 'Unknown';
      case ActiveSlot.legacyFirmware:
        return 'LegacyFirmware';
    }
  }

  int targetSlotAddress(ActiveSlot targetSlot) =>
      (targetSlot == ActiveSlot.slotB) ? imageBStartAddr : imageAStartAddr;

  // ============================================================
  // DOWNLOAD FIRMWARE
  // ============================================================

  //TO TEST THE HARDCODED FIRMWARE
  /*Future<Uint8List> downloadFirmwareBinary(
      {required ActiveSlot activeSlot}) async {
    final targetSlot = targetSlotFor(activeSlot);
    final String slotFolder =
        targetSlot == ActiveSlot.slotA ? 'slotA' : 'slotB';
    final String suffix = targetSlot == ActiveSlot.slotA ? 'slotA' : 'slotB';

    final String assetPath =
        'assets/usb-c-4key/$slotFolder/badgemagic-ch582-$suffix.bin';

    logger.i(
        'OTA: active=${slotName(activeSlot)} -> writing to target=${slotName(targetSlot)}, asset=$assetPath');

    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List firmware = byteData.buffer.asUint8List();

      if (firmware.isEmpty) {
        throw Exception('Asset binary file is empty (0 bytes).');
      }

      logger.i('OTA: firmware asset loaded: ${firmware.length} bytes');
      return firmware;
    } catch (e) {
      throw Exception('Error loading firmware asset ($assetPath): $e');
    }
  }
  */

  Future<Uint8List> downloadFirmwareBinaryFromRemote({
    required ActiveSlot activeSlot,
    required List<dynamic> releaseAssets,
  }) async {
    final targetSlot = targetSlotFor(activeSlot);
    final String slotTag = targetSlot == ActiveSlot.slotA ? 'SlotA' : 'SlotB';
    final String expectedFileName = 'badgemagic-ch582-usb-c-4key_$slotTag.bin';

    logger.i(
      'OTA: active=${slotName(activeSlot)} -> looking for target=${slotName(targetSlot)} remote asset: $expectedFileName',
    );

    dynamic targetAsset;
    for (final asset in releaseAssets) {
      final name = (asset['name'] as String? ?? '').trim();
      if (name.toLowerCase() == expectedFileName.toLowerCase()) {
        targetAsset = asset;
        break;
      }
    }

    if (targetAsset == null) {
      throw Exception(
          'Firmware asset "$expectedFileName" not found in release.');
    }

    final String? downloadUrl = targetAsset['browser_download_url'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw Exception('Download URL missing for asset "$expectedFileName".');
    }

    logger.i('OTA: Downloading firmware from $downloadUrl');

    try {
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP error ${response.statusCode} while downloading firmware.');
      }

      final Uint8List firmware = response.bodyBytes;

      if (firmware.isEmpty) {
        throw Exception('Downloaded firmware binary is empty (0 bytes).');
      }

      logger
          .i('OTA: Firmware downloaded successfully: ${firmware.length} bytes');
      return firmware;
    } catch (e) {
      throw Exception(
          'Error downloading remote firmware ($expectedFileName): $e');
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
      'OTA: ERASE target slot at 0x${targetStartAddr.toRadixString(16)} '
      '($binaryLength bytes, erase block=$flashEraseBlockSize bytes)',
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
        'OTA: Sending $total bytes to ${slotName(targetSlot)} (Chunk: $chunkSize B)...');

    int lastReportedPct = -1;
    int lastEraseBlockIndex = -1;

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
      const int maxAttempts = 5;

      while (!sent) {
        attempt++;

        final connState = await UniversalBle.getConnectionState(deviceId);
        if (connState != BleConnectionState.connected) {
          logger
              .w('OTA: connection lost before offset=$offset, reconnecting...');
          try {
            await UniversalBle.connect(deviceId);
            await Future.delayed(const Duration(milliseconds: 800));
            await UniversalBle.discoverServices(deviceId);
            try {
              await UniversalBle.requestConnectionPriority(
                deviceId,
                BleConnectionPriority.highPerformance,
              );
            } catch (_) {}
          } catch (e) {
            logger.e('OTA: reconnection failed: $e');
            if (attempt >= maxAttempts) {
              throw Exception(
                'OTA failed at offset=$offset: device disconnected and '
                'reconnection failed after $attempt attempts.',
              );
            }
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
        }

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
          logger.e('OTA: timeout offset=$offset (attempt $attempt)');
          UniversalBle.clearQueue(deviceId);
          await Future.delayed(const Duration(milliseconds: 300));
          if (attempt >= maxAttempts) {
            throw Exception(
              'OTA failed at offset=$offset after $attempt attempts: '
              'unstable connection or firmware not responding.',
            );
          }
        } catch (e) {
          logger.w('OTA: write error at offset=$offset (attempt $attempt): $e');
          UniversalBle.clearQueue(deviceId);
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          if (attempt >= maxAttempts) {
            throw Exception(
              'OTA failed at offset=$offset after $attempt attempts: $e',
            );
          }
        }
      }

      final int eraseBlockIndex = offset ~/ flashEraseBlockSize;
      final bool entersNewEraseBlock = eraseBlockIndex != lastEraseBlockIndex;
      lastEraseBlockIndex = eraseBlockIndex;

      if (entersNewEraseBlock) {
        await Future.delayed(const Duration(milliseconds: 20));
      } else {
        await Future.delayed(const Duration(milliseconds: 3));
      }

      final int written = offset + currentSize;
      final double progress = (written / total).clamp(0.0, 1.0);
      final int pct = (progress * 100).floor();
      if (pct != lastReportedPct) {
        lastReportedPct = pct;
        onProgress?.call(progress);
      }
    }

    onProgress?.call(1.0);
    logger.i('OTA: Writing finished.');
  }

  // ============================================================
  // END
  // ============================================================

  Future<void> _end(String deviceId, ActiveSlot targetSlot) async {
    logger.i('OTA: END -> switching active slot to ${slotName(targetSlot)}');

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
      logger.w('OTA: disconnection during badge reboot (expected): $e');
    }

    await Future.delayed(endDelay);
    logger.i('OTA: badge should now be running from ${slotName(targetSlot)}');
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
      logger.w('OTA: update already in progress, request ignored');
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
          logger.i('OTA: negotiated MTU: $negotiatedMtu');
        } catch (e) {
          logger.w('OTA: MTU negotiation failed, using fallback: $e');
        }
      }

      final int firmwareIapMaxBuffer = 240;
      int maxDataPayload = (negotiatedMtu - 7).clamp(16, firmwareIapMaxBuffer);
      maxDataPayload = maxDataPayload & ~3;

      final activeSlot = await queryActiveSlot(deviceId);
      final targetSlot = targetSlotFor(activeSlot);
      final int targetAddr = targetSlotAddress(targetSlot);

      logger.i(
          'OTA: plan -> active=${slotName(activeSlot)}, target=${slotName(targetSlot)}, '
          'targetAddr=0x${targetAddr.toRadixString(16)}, chunkSize=$maxDataPayload B');

      final firmware = await downloadFirmwareBinaryFromRemote(
        activeSlot: activeSlot,
        releaseAssets: releaseAssets,
      );

      // UNCOMMENT TO TEST HARDCODED FIRMWARE
      //final firmware = await downloadFirmwareBinary(activeSlot: activeSlot);

      await _erase(deviceId, targetAddr, firmware.length);

      await _program(
        deviceId,
        firmware,
        targetSlot: targetSlot,
        maxChunkSize: maxDataPayload,
        onProgress: onProgress,
      );

      await _end(deviceId, targetSlot);

      logger.i('OTA: update completed successfully -> ${slotName(targetSlot)}');
    } catch (e) {
      logger.e('OTA: update failed: $e');
      rethrow;
    } finally {
      _updateInProgress = false;
    }
  }
}
