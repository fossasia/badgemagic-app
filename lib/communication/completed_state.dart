import 'package:badgemagic/communication/base_ble_state.dart';
import 'package:get_it/get_it.dart';

import 'package:badgemagic/view/widgets/ble_progress_dialog.dart';
import 'package:badgemagic/view/widgets/ble_progress_dialog_controller.dart';

class CompletedState extends NormalBleState {
  final bool isSuccess;
  final String message;
  final bleDialogController = GetIt.instance<BleDialogController>();

  CompletedState({required this.isSuccess, required this.message});

  @override
  Future<BleState?> processState() async {
    if (isSuccess) {
      bleDialogController.update(BleDialogStatus.success, message);
    } else {
      bleDialogController.update(BleDialogStatus.error, message);
    }
    return null;
  }
}
