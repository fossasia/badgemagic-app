import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/transport/badge_transport.dart';

class UsbHidBadgeTransport extends BadgeTransport {
  @override
  BadgeTransportType get type => BadgeTransportType.usb;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> send(DataTransferManager manager) async {
    throw BadgeTransportException('USB is not supported on this platform.');
  }
}
