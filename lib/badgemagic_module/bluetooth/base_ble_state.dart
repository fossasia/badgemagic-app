import 'package:badgemagic/badgemagic_module/bluetooth/completed_state.dart';
import 'package:badgemagic/badgemagic_module/utils/toast_utils.dart';
import 'package:logger/logger.dart';

abstract class BleState {
  Future<BleState?> process();
}

abstract class NormalBleState extends BleState {
  final logger = Logger();
  final toast = ToastUtils();

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
  final logger = Logger();
  final toast = ToastUtils();

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
          lastException =
              Exception("Max retries reached. Last exception: $lastException");
        }
      }
    }

    // After max retries, return a CompletedState indicating failure.
    return CompletedState(
        isSuccess: false,
        message: lastException?.toString() ?? "Unknown error");
  }
}
