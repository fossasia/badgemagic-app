import 'dart:convert';
import 'dart:io';

import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';

class QrCodeHelper {
  static const String _scheme = 'BMQR1:';

  static const int maxPayloadLength = 2800;

  static String? encode(Map<String, dynamic> badgeJson) {
    try {
      final List<int> raw = utf8.encode(jsonEncode(badgeJson));
      final List<int> compressed = gzip.encode(raw);
      final String payload = '$_scheme${base64Url.encode(compressed)}';
      if (payload.length > maxPayloadLength) {
        logger.i('QR payload too large: ${payload.length} chars');
        return null;
      }
      return payload;
    } catch (e) {
      logger.i('Error encoding badge for QR: $e');
      return null;
    }
  }

  static bool isBadgePayload(String raw) => raw.startsWith(_scheme);

  static Map<String, dynamic>? decode(String raw) {
    try {
      if (!isBadgePayload(raw)) {
        return null;
      }
      final String encoded = raw.substring(_scheme.length);
      final List<int> compressed = base64Url.decode(encoded);
      final List<int> raw0 = gzip.decode(compressed);
      final dynamic decoded = jsonDecode(utf8.decode(raw0));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      logger.i('Error decoding badge from QR: $e');
      return null;
    }
  }
}
