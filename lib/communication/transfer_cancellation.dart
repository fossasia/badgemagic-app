class TransferCancellation {
  static TransferCancellation? _active;

  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  static TransferCancellation startNew() {
    final token = TransferCancellation();
    _active = token;
    return token;
  }

  static void cancelActive() {
    _active?.cancel();
  }
}
