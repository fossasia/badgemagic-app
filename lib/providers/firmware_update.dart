import 'dart:convert';
import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/others/toast_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirmwareUpdateService {
  static const String _apiLatestUrl =
      'https://api.github.com/repos/fossasia/badgemagic-firmware/releases/latest';
  static const String _prefKeySkipVersion = 'skip_firmware_version_';

  /// Fetches the latest release from GitHub and returns the info if a prompt is needed.
  Future<Map<String, String>?> checkForUpdates() async {
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

        if (version.isEmpty) return null;

        // Format the ISO date (e.g., 2026-03-10T...) into a readable format (e.g., Jun 19, 2026)
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

  /// Placeholder method for the actual flashing/update procedure.
  Future<void> executeFirmwareUpdate(String version) async {
    // TODO: Implement the OTA transmission logic here in the future
    logger.i('Starting firmware update execution for version: $version...');
  }
}
