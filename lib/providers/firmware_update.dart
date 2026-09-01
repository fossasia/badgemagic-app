import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../others/app_logger.dart';
import '../others/localization_service.dart';
import '../others/toast_utils.dart';

class WchUsbIspFlasher {
  static const MethodChannel _channel =
      MethodChannel('org.fossasia.badgemagic/wch_isp');
  static const String _apiLatestUrl =
      'https://api.github.com/repos/fossasia/badgemagic-firmware/releases/latest';

  final l10n = GetIt.instance.get<LocalizationService>().l10n;

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
        orElse: () => throw Exception('No .bin file found'),
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
      ToastUtils().showErrorToast(l10n.badgeIspNotFound);
      throw Exception("Badge WCH ISP not found");
    }
    final bool hasPermission = device['hasPermission'] ?? false;
    if (!hasPermission) {
      final bool granted =
          await _channel.invokeMethod('requestUsbPermission') ?? false;
      if (!granted) {
        ToastUtils().showErrorToast(l10n.usbPermissionDenied);
        throw Exception("USB permission denied.");
      }
    }

    await _channel.invokeMethod('flashFirmware', {
      'firmware': firmwareData,
    });

    onProgress?.call(1.0);
    ToastUtils().showToast(l10n.firmwareUpdateSuccessShort);
  }

  Future<String?> _findWchispBinary() async {
    final which = await Process.run('which', ['wchisp']);
    if (which.exitCode == 0) {
      final path = (which.stdout as String).trim();
      if (path.isNotEmpty) return path;
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['XDG_HOME'] ?? '';

    final candidates = <String>[
      if (home.isNotEmpty) '$home/.cargo/bin/wchisp',
      if (home.isNotEmpty) '$home/.local/bin/wchisp',
      '/usr/local/bin/wchisp',
      '/usr/bin/wchisp',
      '/opt/wchisp/wchisp',
    ];

    for (final path in candidates) {
      if (await File(path).exists()) return path;
    }

    return null;
  }

  Future<void> flashMergedBinaryLinux({
    required Uint8List firmwareData,
    Function(double progress)? onProgress,
  }) async {
    final wchispPath = await _findWchispBinary();
    if (wchispPath == null) {
      ToastUtils()
          .showErrorToast("wchisp not found. Verify that it is installed "
              "(e.g. 'cargo install wchisp') and that its path is in PATH, "
              "or report it to search in a custom location.");
      throw Exception("wchisp not found (PATH and common locations)");
    }

    final tempDir = await Directory.systemTemp.createTemp('badgemagic_fw_');
    final fwFile = File('${tempDir.path}/merged.bin');
    await fwFile.writeAsBytes(firmwareData);

    try {
      final process = await Process.start(wchispPath, ['flash', fwFile.path]);

      final stderrBuf = StringBuffer();
      process.stdout.transform(const SystemEncoding().decoder).listen((line) {
        logger.i('wchisp: $line');
      });
      process.stderr.transform(const SystemEncoding().decoder).listen((line) {
        stderrBuf.writeln(line);
        logger.e('wchisp: $line');
      });

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        final err = stderrBuf.toString();
        if (err.toLowerCase().contains('permission') ||
            err.toLowerCase().contains('access') ||
            err.toLowerCase().contains('udev')) {
          ToastUtils().showErrorToast(
              "USB permission error: configure udev rules for the badge.");
        } else {
          ToastUtils().showErrorToast("Error during flash: $err");
        }
        throw Exception("wchisp flash failed (exit $exitCode): $err");
      }

      onProgress?.call(1.0);
      ToastUtils().showToast(l10n.firmwareUpdateSuccessShort);
    } finally {
      if (await fwFile.exists()) await fwFile.delete();
      await tempDir.delete(recursive: true);
    }
  }
}
