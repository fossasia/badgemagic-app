import 'package:badgemagic/communication/write_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDisconnectAcceptable', () {
    test('accepts a disconnect after the last chunk', () {
      expect(
        WriteState.isDisconnectAcceptable(chunkIndex: 10, totalChunks: 10),
        isTrue,
      );
    });

    test('rejects a disconnect before the last chunk', () {
      expect(
        WriteState.isDisconnectAcceptable(chunkIndex: 9, totalChunks: 10),
        isFalse,
      );
    });

    test('rejects a disconnect at 85 percent of the data', () {
      expect(
        WriteState.isDisconnectAcceptable(chunkIndex: 85, totalChunks: 100),
        isFalse,
      );
    });
  });
}
