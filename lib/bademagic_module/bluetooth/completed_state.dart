import 'package:badgemagic/bademagic_module/bluetooth/base_ble_state.dart';

class CompletedState extends NormalBleState {
  final bool isSuccess;
  final String message;
  final bool isNextGen;

  CompletedState(
      {required this.isSuccess, required this.message, this.isNextGen = false});

  @override
  Future<BleState?> processState() async {
    if (isSuccess) {
      toast.showToast(message);
    } else {
      toast.showErrorToast(message);
    }
    return null;
  }
}
