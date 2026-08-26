import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hid_tool/hid_tool.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WchUsbIspFlasher {
  static const String _apiLatestUrl =
      'https://api.github.com/repos/fossasia/badgemagic-firmware/releases/latest';

  // Vendor e Product ID del bootloader ISP WCH
  static const int wchVendorId = 0x4348;
  static const int wchProductId = 0x55e0;

  // Opcode ISP Hardware WCH
  static const int cmdIdentify = 0xa1;
  static const int cmdReset = 0xa2;
  static const int cmdErase = 0xa4;
  static const int cmdProgram = 0xa5;

  static const int ispChunkSize = 56;

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_apiLatestUrl),
        headers: {'Accept': 'application/vnd.github+json'},
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
    } catch (_) {}
    return null;
  }

  Future<Uint8List> downloadFirmwareBinary(List<dynamic> assets) async {
    final asset = assets.firstWhere(
      (a) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        return name.contains('merged') && name.endsWith('.bin');
      },
      orElse: () => assets.firstWhere(
        (a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.bin'),
        orElse: () =>
            throw Exception('Nessun file .bin trovato nella release.'),
      ),
    );

    final String downloadUrl = asset['browser_download_url'];
    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception(
          'Download fallito da $downloadUrl (HTTP ${response.statusCode})');
    }

    return response.bodyBytes;
  }

  Future<void> flashMergedBinary({
    required Uint8List firmwareData,
    Function(double progress)? onProgress,
  }) async {
    // 1. Cerca il dispositivo HID WCH Bootloader
    final List<HidDevice> allDevices = await Hid.getDevices();
    final target = allDevices.firstWhere(
      (d) =>
          (d.vendorId == wchVendorId && d.productId == wchProductId) ||
          (d.vendorId == 0x1a86 && d.productId == 0xfe10),
      orElse: () => throw Exception(
        'Badge in modalità WCH ISP non trovato. Collega il cavo OTG tenendo premuto il pulsante di accensione.',
      ),
    );

    // 2. Apri la connessione HID
    await target.open();

    try {
      // 3. Handshake / Identify
      await target.sendReport(
        Uint8List.fromList([cmdIdentify, 0x12, 0x00]),
        reportId: 0x00,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // 4. Erase Flash
      final erasePacket = Uint8List.fromList([
        cmdErase,
        0x04,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      await target.sendReport(erasePacket, reportId: 0x00);
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Scrittura Firmware
      final int total = firmwareData.length;
      for (int offset = 0; offset < total; offset += ispChunkSize) {
        final int end =
            (offset + ispChunkSize < total) ? offset + ispChunkSize : total;
        final chunk = firmwareData.sublist(offset, end);

        final int addrLsb = offset & 0xff;
        final int addrMsb = (offset >> 8) & 0xff;
        final int addrHsb = (offset >> 16) & 0xff;

        final packet = Uint8List.fromList([
          cmdProgram,
          chunk.length,
          addrLsb,
          addrMsb,
          addrHsb,
          0x00,
          ...chunk,
        ]);

        await target.sendReport(packet, reportId: 0x00);

        final progress = (end / total).clamp(0.0, 1.0);
        onProgress?.call(progress);

        await Future.delayed(const Duration(milliseconds: 4));
      }

      // 6. Reset CPU
      try {
        await target.sendReport(
          Uint8List.fromList([cmdReset, 0x01, 0x01]),
          reportId: 0x00,
        );
      } catch (_) {}
    } finally {
      await target.close();
    }
  }
}
