import 'package:badgemagic/bademagic_module/bluetooth/completed_state.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../services/localization_service.dart';

abstract class BleState {
  Future<BleState?> process();
}

abstract class NormalBleState extends BleState {
  final logger = Logger();

  Future<BleState?> processState();

  @override
  Future<BleState?> process() async {
    try {
      return await processState();
    } on Exception catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      return CompletedState(isSuccess: false, message: errorMessage);
    }
  }
}

abstract class RetryBleState extends BleState {
  final l10n = GetIt.instance.get<LocalizationService>().l10n;
  final logger = Logger();

  final _maxRetries = 3;

  Future<BleState?> processState();

  @override
  Future<BleState?> process() async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < _maxRetries) {
      try {
        return await processState();
      } on Exception catch (e) {
        logger.e(e);
        lastException = e;
        attempt++;
        if (attempt < _maxRetries) {
          logger.d("Retrying ($attempt/$_maxRetries)...");
        } else {
          logger.e("Max retries reached. Last exception: $lastException");
          lastException = Exception(l10n.transferFailed);
        }
      }
    }

    // After max retries, return a CompletedState indicating failure.
    return CompletedState(
        isSuccess: false,
        message: lastException?.toString() ?? l10n.unknownError);
  }
}
