import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';

enum BadgeTransportType { bluetooth, usb }

class BadgeTransportException implements Exception {
  final String message;
  BadgeTransportException(this.message);

  @override
  String toString() => message;
}

abstract class BadgeTransport {
  BadgeTransportType get type;

  Future<bool> isAvailable();

  Future<void> send(DataTransferManager manager);
}
