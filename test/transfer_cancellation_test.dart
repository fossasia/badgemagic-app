import 'package:badgemagic/communication/transfer_cancellation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new token is not cancelled', () {
    expect(TransferCancellation().isCancelled, isFalse);
  });

  test('a cancelled token stays cancelled', () async {
    final token = TransferCancellation();
    token.cancel();
    await Future.delayed(const Duration(milliseconds: 1200));
    expect(token.isCancelled, isTrue);
  });

  test('cancelActive cancels the transfer that started last', () {
    final token = TransferCancellation.startNew();
    TransferCancellation.cancelActive();
    expect(token.isCancelled, isTrue);
  });

  test('starting a new transfer does not clear an earlier cancel', () {
    final first = TransferCancellation.startNew();
    TransferCancellation.cancelActive();
    final second = TransferCancellation.startNew();
    expect(first.isCancelled, isTrue);
    expect(second.isCancelled, isFalse);
  });

  test('cancelActive only cancels the newest transfer', () {
    final first = TransferCancellation.startNew();
    final second = TransferCancellation.startNew();
    TransferCancellation.cancelActive();
    expect(second.isCancelled, isTrue);
    expect(first.isCancelled, isFalse);
  });
}
