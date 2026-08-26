import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quick_usb/quick_usb.dart';

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

  /// Controlla la versione più recente rilasciata su GitHub
  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(_apiLatestUrl),
        headers: {
          'Accept': 'application/vnd.github+json',
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

  /// Scarica il file merged.bin dagli asset della release
  Future<Uint8List> downloadFirmwareBinary(List<dynamic> assets) async {
    final asset = assets.firstWhere(
      (a) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        return name.contains('merged') && name.endsWith('.bin');
      },
      orElse: () {
        return assets.firstWhere(
          (a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.bin'),
          orElse: () => throw Exception(
              'Nessun file firmware .bin trovato nella release.'),
        );
      },
    );

    final String downloadUrl = asset['browser_download_url'];
    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception(
          'Download fallito da $downloadUrl (HTTP ${response.statusCode})');
    }

    return response.bodyBytes;
  }

  /// Esegue la cancellazione e la scrittura del file binario via USB ISP
  Future<void> flashMergedBinary({
    required Uint8List firmwareData,
    Function(double progress)? onProgress,
  }) async {
    await QuickUsb.init();

    try {
      final devices = await QuickUsb.getDeviceList();
      final target = devices.firstWhere(
        (d) =>
            (d.vendorId == wchVendorId && d.productId == wchProductId) ||
            (d.vendorId == 0x1a86 && d.productId == 0xfe10),
        orElse: () => throw Exception(
          'Dispositivo WCH ISP non trovato. Verifica il cavo OTG e che il badge sia in modalità bootloader (tasto premuto).',
        ),
      );

      final hasPermission = await QuickUsb.hasPermission(target);
      if (!hasPermission) {
        final granted = await QuickUsb.requestPermission(target);
        if (!granted) {
          throw Exception('Permesso USB negato dall\'utente.');
        }
      }

      final opened = await QuickUsb.openDevice(target);
      if (!opened) {
        throw Exception('Impossibile aprire la connessione USB.');
      }

      const int usbDirectionOut = 0;

      final UsbConfiguration configuration = await QuickUsb.getConfiguration(0);
      final UsbInterface interface = configuration.interfaces.first;

      final UsbEndpoint endpoint = interface.endpoints.firstWhere(
        (e) => e.direction == usbDirectionOut || (e.endpointNumber & 0x80) == 0,
        orElse: () => interface.endpoints.first,
      );

      await QuickUsb.claimInterface(interface);

      try {
        // 1. Identify
        await _sendIspPacket(
            endpoint, Uint8List.fromList([cmdIdentify, 0x12, 0x00]));
        await Future.delayed(const Duration(milliseconds: 50));

        // 2. Erase All Code Flash (0xA4)
        final erasePacket = Uint8List.fromList([
          cmdErase,
          0x04,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
        ]);
        await _sendIspPacket(endpoint, erasePacket);
        await Future.delayed(const Duration(milliseconds: 500));

        // 3. Program Flash (0xA5)
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

          await _sendIspPacket(endpoint, packet);

          final progress = (end / total).clamp(0.0, 1.0);
          onProgress?.call(progress);

          await Future.delayed(const Duration(milliseconds: 5));
        }

        // 4. Reset CPU (0xA2)
        try {
          await _sendIspPacket(
              endpoint, Uint8List.fromList([cmdReset, 0x01, 0x01]));
        } catch (_) {}
      } finally {
        await QuickUsb.releaseInterface(interface);
        await QuickUsb.closeDevice();
      }
    } finally {
      await QuickUsb.exit();
    }
  }

  Future<void> _sendIspPacket(
    UsbEndpoint endpoint,
    Uint8List data,
  ) async {
    final result = await QuickUsb.bulkTransferOut(
      endpoint,
      data,
      timeout: 2000,
    );
    if (result < 0) {
      throw Exception('Errore di trasferimento USB ISP (codice: $result)');
    }
  }
}
