import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'app_logger.dart';

/// Thrown when a firmware file cannot be trusted: its SHA-256 does not
/// match the digest published with the release, or the published digest
/// is not a valid SHA-256.
class FirmwareIntegrityException implements Exception {
  final String? expected;
  final String? actual;

  const FirmwareIntegrityException({this.expected, this.actual});

  @override
  String toString() => expected == null
      ? 'The SHA-256 digest published for this firmware is not valid'
      : 'Firmware checksum mismatch (expected $expected, got $actual)';
}

/// Reads a GitHub asset digest such as "sha256:<64 hex chars>" and returns
/// the lower-case hash. Returns null if the release has no digest for the
/// file. Throws [FirmwareIntegrityException] if a digest is there but is
/// not a valid SHA-256, because then the file cannot be trusted.
String? parseSha256Digest(Object? digest) {
  if (digest == null) return null;
  final match = digest is String
      ? RegExp(r'^sha256:([0-9a-fA-F]{64})$').firstMatch(digest.trim())
      : null;
  if (match == null) throw const FirmwareIntegrityException();
  return match.group(1)!.toLowerCase();
}

/// Finds the release asset with [downloadUrl] and returns its SHA-256, or
/// null if the asset or its digest is not there. Throws
/// [FirmwareIntegrityException] if the digest is not valid.
String? sha256ForAssetUrl(List<dynamic> assets, String downloadUrl) {
  for (final asset in assets) {
    if (asset is Map && asset['browser_download_url'] == downloadUrl) {
      return parseSha256Digest(asset['digest']);
    }
  }
  return null;
}

/// Throws [FirmwareIntegrityException] if [data] does not match
/// [expectedSha256]. If no digest is published, only a warning is logged.
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
