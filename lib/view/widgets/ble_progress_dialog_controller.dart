import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

import '../../services/localization_service.dart';
import 'ble_progress_dialog.dart';

class BleDialogController {
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  final ValueNotifier<BleDialogStatus> status =
      ValueNotifier(BleDialogStatus.searching);
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  late final ValueNotifier<String> message =
      ValueNotifier(l10n.searchingDeviceBLE);

  void update(BleDialogStatus newStatus, String newMessage,
      {double newProgress = 0.0}) {
    status.value = newStatus;
    message.value = newMessage;
    progress.value = newProgress;
  }
}
