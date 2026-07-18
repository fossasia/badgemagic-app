import 'package:badgemagic/bademagic_module/bluetooth/datagenerator.dart';
import 'package:badgemagic/bademagic_module/transport/badge_transport.dart';
import 'package:badgemagic/providers/transport_provider.dart';
import 'package:get_it/get_it.dart';

List<List<int>> boolToIntBitmap(List<List<bool>> bitmap) {
  return bitmap.map((row) => row.map((b) => b ? 1 : 0).toList()).toList();
}

Future<bool> ensureTransportReady() async {
  final isUsb = GetIt.instance<TransportProvider>().transportType ==
      BadgeTransportType.usb;
  if (isUsb) return true;

  return checkAdapterState();
}
