import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'app_logger.dart';

/// Thrown when a downloaded firmware file does not match the SHA-256
/// digest published with the release.
class FirmwareIntegrityException implements Exception {
  final String expected;
  final String actual;

  const FirmwareIntegrityException({
    required this.expected,
    required this.actual,
  });

  @override
  String toString() =>
      'Firmware checksum mismatch (expected $expected, got $actual)';
}

/// Reads a GitHub asset digest such as "sha256:<64 hex chars>" and returns
/// the lower-case hash, or null if the value is missing or malformed.
String? parseSha256Digest(String? digest) {
  if (digest == null) return null;
  final match = RegExp(r'^sha256:([0-9a-fA-F]{64})$').firstMatch(digest.trim());
  return match?.group(1)?.toLowerCase();
}

/// Finds the release asset with [downloadUrl] and returns its SHA-256,
/// or null if the asset or its digest is not there.
String? sha256ForAssetUrl(List<dynamic> assets, String downloadUrl) {
  for (final asset in assets) {
    if (asset is Map && asset['browser_download_url'] == downloadUrl) {
      final digest = asset['digest'];
      return parseSha256Digest(digest is String ? digest : null);
    }
  }
  return null;
}

/// Throws [FirmwareIntegrityException] if [data] does not match
/// [expectedSha256]. If no digest is known, only a warning is logged.
void verifyFirmwareSha256(Uint8List data, String? expectedSha256) {
  if (expectedSha256 == null) {
    logger.w('No SHA-256 digest published for this firmware, skipping check');
    return;
  }
  final expected = expectedSha256.toLowerCase();
  final actual = sha256.convert(data).toString();
  if (actual != expected) {
    throw FirmwareIntegrityException(expected: expected, actual: actual);
  }
}
