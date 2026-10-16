/// Cancel request of a single BLE transfer.
///
/// Every transfer gets its own token. Starting a new transfer never changes
/// the token of an older one, so a transfer that is still stopping cannot
/// be un-cancelled, and a new transfer is not stopped by an old request.
class TransferCancellation {
  static TransferCancellation? _active;

  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  /// Creates the token for a new transfer and makes it the active one.
  static TransferCancellation startNew() {
    final token = TransferCancellation();
    _active = token;
    return token;
  }

  /// Cancels the transfer that was started last, the one the user sees.
  static void cancelActive() {
    _active?.cancel();
  }
}
