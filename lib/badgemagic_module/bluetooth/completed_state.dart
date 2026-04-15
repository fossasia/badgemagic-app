import 'package:badgemagic/badgemagic_module/bluetooth/base_ble_state.dart';

class CompletedState extends NormalBleState {
  final bool isSuccess;
  final String message;

  CompletedState({required this.isSuccess, required this.message});

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
