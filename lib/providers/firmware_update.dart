import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../others/toast_utils.dart';

class WchUsbIspFlasher {
  static const MethodChannel _channel =
      MethodChannel('org.fossasia.badgemagic/wch_isp');
  static const String _apiLatestUrl =
      'https://api.github.com/repos/fossasia/badgemagic-firmware/releases/latest';

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
            throw Exception('No .bin file found'),
      ),
    );

    final String downloadUrl = asset['browser_download_url'];
    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception(
          'Download failed from $downloadUrl (HTTP ${response.statusCode})');
    }

    return response.bodyBytes;
  }

  Future<void> flashMergedBinary({
    required Uint8List firmwareData,
    Function(double progress)? onProgress,
  }) async {
    final dynamic device = await _channel.invokeMethod('getIspDevice');
    if (device == null) {
      ToastUtils()
          .showErrorToast("Badge ISP not found. Connect the ledtag with the boot button pressed.");
      throw Exception("Badge WCH ISP not found");
    }
    final bool hasPermission = device['hasPermission'] ?? false;
    if (!hasPermission) {
      final bool granted =
          await _channel.invokeMethod('requestUsbPermission') ?? false;
      if (!granted) {
        ToastUtils().showErrorToast("USB permission denied by user");
        throw Exception("USB permission denied.");
      }
    }

    await _channel.invokeMethod('flashFirmware', {
      'firmware': firmwareData,
    });

    onProgress?.call(1.0);
    ToastUtils().showToast("Firmware updated successfully!");
  }
}
