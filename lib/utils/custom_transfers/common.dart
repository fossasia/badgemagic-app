import 'package:badgemagic/bademagic_module/transport/badge_transport.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/providers/transport_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';

List<List<int>> boolToIntBitmap(List<List<bool>> bitmap) {
  return bitmap.map((row) => row.map((b) => b ? 1 : 0).toList()).toList();
}

Future<bool> ensureTransportReady() async {
  final isUsb = GetIt.instance<TransportProvider>().transportType ==
      BadgeTransportType.usb;
  if (isUsb) return true;

  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    ToastUtils().showErrorToast('Please turn on Bluetooth');
    return false;
  }
  return true;
}
