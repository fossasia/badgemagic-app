import 'dart:typed_data';

import 'package:badgemagic/others/firmware_integrity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // SHA-256 of the three bytes "abc"
  const abcHash =
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  final abcBytes = Uint8List.fromList([0x61, 0x62, 0x63]);

  group('parseSha256Digest', () {
    test('returns the hash from a GitHub digest', () {
      expect(parseSha256Digest('sha256:$abcHash'), abcHash);
    });

    test('lower-cases the hash', () {
      expect(parseSha256Digest('sha256:${abcHash.toUpperCase()}'), abcHash);
    });

    test('returns null when there is no digest', () {
      expect(parseSha256Digest(null), isNull);
    });

    test('throws for a malformed digest', () {
      for (final bad in ['', 'md5:abc', 'sha256:1234', abcHash]) {
        expect(
          () => parseSha256Digest(bad),
          throwsA(isA<FirmwareIntegrityException>()),
        );
      }
    });

    test('throws for a digest that is not a string', () {
      expect(
        () => parseSha256Digest(42),
        throwsA(isA<FirmwareIntegrityException>()),
      );
      expect(
        () => parseSha256Digest(['sha256:$abcHash']),
        throwsA(isA<FirmwareIntegrityException>()),
      );
    });
  });

  group('sha256ForAssetUrl', () {
    final assets = [
      {
        'browser_download_url': 'https://example.com/a.bin',
        'digest': 'sha256:$abcHash',
      },
      {'browser_download_url': 'https://example.com/b.bin', 'digest': null},
      {'browser_download_url': 'https://example.com/d.bin', 'digest': 42},
    ];

    test('finds the digest of the matching asset', () {
      expect(sha256ForAssetUrl(assets, 'https://example.com/a.bin'), abcHash);
    });

    test('returns null when the asset has no digest', () {
      expect(sha256ForAssetUrl(assets, 'https://example.com/b.bin'), isNull);
    });

    test('throws when the digest is not valid', () {
      expect(
        () => sha256ForAssetUrl(assets, 'https://example.com/d.bin'),
        throwsA(isA<FirmwareIntegrityException>()),
      );
    });

    test('returns null for an unknown url', () {
      expect(sha256ForAssetUrl(assets, 'https://example.com/c.bin'), isNull);
    });
  });

  group('verifyFirmwareSha256', () {
    test('accepts data that matches the digest', () {
      expect(() => verifyFirmwareSha256(abcBytes, abcHash), returnsNormally);
    });

    test('ignores case of the expected hash', () {
      expect(
        () => verifyFirmwareSha256(abcBytes, abcHash.toUpperCase()),
        returnsNormally,
      );
    });

    test('throws when the data does not match', () {
      expect(
        () => verifyFirmwareSha256(Uint8List.fromList([1, 2, 3]), abcHash),
        throwsA(isA<FirmwareIntegrityException>()),
      );
    });

    test('throws for truncated data', () {
      expect(
        () => verifyFirmwareSha256(Uint8List.fromList([0x61, 0x62]), abcHash),
        throwsA(isA<FirmwareIntegrityException>()),
      );
    });

    test('skips the check when no digest is published', () {
      expect(() => verifyFirmwareSha256(abcBytes, null), returnsNormally);
    });
  });
}
