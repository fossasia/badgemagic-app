import 'dart:async';
import 'dart:convert';
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

enum ActiveSlot { slotA, slotB, unknown }

class FirmwareUpdateService {
  static const String _apiLatestUrl =
      'https://api.github.com/repos/fossasia/badgemagic-firmware/releases/latest';
  static const String _prefKeySkipVersion = 'skip_firmware_version_';

  // UUID per il servizio IAP/OTA
  static const String otaServiceUuid = "fee0";
  static const String otaCharacteristicUuid = "fee1";

  // Comandi del protocollo IAP
  static const int cmdIapErase = 0x81;
  static const int cmdIapProm = 0x82;
  static const int cmdIapEnd = 0x83;
  static const int cmdIapInfo = 0x84;

  /// Cerca aggiornamenti su GitHub Releases
  Future<Map<String, dynamic>?> checkForUpdates() async {
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

        if (version.isEmpty) return null;

        String formattedDate = rawDate;
        if (rawDate.isNotEmpty) {
          try {
            final DateTime parsedDate = DateTime.parse(rawDate);
            formattedDate = DateFormat.yMMMd().format(parsedDate);
          } catch (_) {}
        }

        return {
          'version': version,
          'date': formattedDate,
          'assets': assets,
        };
      } else {
        final l10n = GetIt.instance.get<LocalizationService>().l10n;
        ToastUtils().showToast(l10n.checkFirmwareFailed);
      }
    } catch (e) {
      logger.e('Firmware update check failed: $e');
    }
    return null;
  }

  Future<void> skipVersionPermanently(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeySkipVersion$version', true);
  }

  /// Interroga il badge via BLE per capire qual è lo Slot attivo (CMD_IAP_INFO 0x84)
  Future<ActiveSlot> queryActiveSlot(String deviceId) async {
    final completer = Completer<ActiveSlot>();

    // 1. Abilita le notifiche sulla caratteristica OTA/IAP
    await UniversalBle.subscribeNotifications(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
    );

    // 2. Ascolta lo stream dei dati ricevuti per questa caratteristica
    StreamSubscription? subscription;
    subscription = UniversalBle.characteristicValueStream(
      deviceId,
      otaCharacteristicUuid,
    ).listen((Uint8List data) {
      if (data.isNotEmpty) {
        final byte0 = data[0];
        if (byte0 == 0x01) {
          completer.complete(ActiveSlot.slotA);
        } else if (byte0 == 0x02) {
          completer.complete(ActiveSlot.slotB);
        } else {
          completer.complete(ActiveSlot.unknown);
        }
        subscription?.cancel();
      }
    });

    // 3. Invia il comando CMD_IAP_INFO (0x84)
    final List<int> infoCommand = [cmdIapInfo, ...List.filled(15, 0)];
    await UniversalBle.write(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
      Uint8List.fromList(infoCommand),
      withoutResponse: false,
    );

    // 4. Gestione timeout
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        subscription?.cancel();
        // Disiscriviti in caso di timeout
        UniversalBle.unsubscribe(deviceId, otaServiceUuid, otaCharacteristicUuid);
        return ActiveSlot.unknown;
      },
    );
  }

  /// Scarica il file .bin corretto da GitHub in base allo slot di destinazione
  Future<Uint8List> downloadFirmwareBinary({
    required List<dynamic> assets,
    required String hardwareVariant, // es: "usbc_4key"
    required ActiveSlot activeSlot,
  }) async {
    // Determina lo slot opposto a quello attualmente in uso
    String targetSlot;
    if (activeSlot == ActiveSlot.slotA) {
      targetSlot = "SlotB";
    } else if (activeSlot == ActiveSlot.slotB) {
      targetSlot = "SlotA";
    } else {
      logger.w("Active slot unknown, defaulting to SlotA target.");
      targetSlot = "SlotA";
    }

    // Costruisci il nome atteso del file release (es: badgemagic_usbc_4key_SlotB.bin)
    final expectedFileName = 'badgemagic_${hardwareVariant}_$targetSlot.bin';

    final asset = assets.firstWhere(
          (a) => (a['name'] as String).toLowerCase() == expectedFileName.toLowerCase(),
      orElse: () => throw Exception('Binary asset not found: $expectedFileName'),
    );

    final String downloadUrl = asset['browser_download_url'];
    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download firmware binary from $downloadUrl');
    }
  }

  Future<BleDevice?> scanForBadge({
    required BadgeScanMode mode,
    required List<String> allowedNames,
  }) async {
    final completer = Completer<BleDevice?>();
    StreamSubscription<BleDevice>? subscription;

    final normalizedNames = allowedNames
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    subscription = UniversalBle.scanStream.listen((device) async {
      final matchesUuid = device.services.contains(serviceUuid);
      final deviceName = (device.name ?? "").trim().toLowerCase();
      final matchesName = mode == BadgeScanMode.any || normalizedNames.contains(deviceName);

      if (matchesUuid && matchesName) {
        subscription?.cancel();
        await UniversalBle.stopScan();
        if (!completer.isCompleted) {
          completer.complete(device);
        }
      }
    });

    await UniversalBle.startScan(
      scanFilter: ScanFilter(withServices: [serviceUuid]),
    );

    // Timeout di 10 secondi
    Timer(const Duration(seconds: 10), () async {
      await UniversalBle.stopScan();
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Esegue l'aggiornamento OTA via BLE verso la targhetta
  Future<void> executeFirmwareUpdate({
    required String deviceId,
    required List<dynamic> releaseAssets,
    required String hardwareVariant,
    Function(double progress)? onProgress,
  }) async {
    // 1. Chiedi lo slot attivo
    final activeSlot = await queryActiveSlot(deviceId);

    // 2. Scarica il file .bin (restituisce Uint8List)
    final firmwareBytes = await downloadFirmwareBinary(
      assets: releaseAssets,
      hardwareVariant: hardwareVariant,
      activeSlot: activeSlot,
    );

    // 3. Cancellazione dello slot inattivo (CMD_IAP_ERASE 0x81)
    final eraseCommand = Uint8List.fromList([cmdIapErase, ...List.filled(15, 0)]);
    await UniversalBle.write(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
      eraseCommand,
    );
    await Future.delayed(const Duration(milliseconds: 500));

    // 4. Invio a blocchi da 64 byte (CMD_IAP_PROM 0x82)
    const int chunkSize = 64;
    final int totalBytes = firmwareBytes.length;

    for (int i = 0; i < totalBytes; i += chunkSize) {
      final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
      final chunk = firmwareBytes.sublist(i, end);

      final promPacket = Uint8List.fromList([cmdIapProm, ...chunk]);

      await UniversalBle.write(
        deviceId,
        otaServiceUuid,
        otaCharacteristicUuid,
        promPacket,
        withoutResponse: true,
      );

      if (onProgress != null) {
        onProgress(end / totalBytes);
      }

      await Future.delayed(const Duration(milliseconds: 20));
    }

    // 5. Comando finale di riavvio (CMD_IAP_END 0x83)
    final endCommand = Uint8List.fromList([cmdIapEnd, ...List.filled(15, 0)]);
    await UniversalBle.write(
      deviceId,
      otaServiceUuid,
      otaCharacteristicUuid,
      endCommand,
    );
  }
}